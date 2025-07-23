-- Users and authentication
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    full_name VARCHAR(100),
    role VARCHAR(20) DEFAULT 'reviewer',
    avatar_url TEXT,
    github_username VARCHAR(50),
    github_user_id INTEGER,
    github_access_token TEXT, -- Encrypted
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- GitHub repository integrations
CREATE TABLE github_repositories (
    id SERIAL PRIMARY KEY,
    owner VARCHAR(100) NOT NULL,
    repo_name VARCHAR(100) NOT NULL,
    full_name VARCHAR(200) NOT NULL, -- owner/repo
    github_repo_id BIGINT UNIQUE NOT NULL,
    webhook_id BIGINT,
    webhook_secret VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    config JSONB, -- Repository configuration from .codereview.yml
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(owner, repo_name)
);

-- Repository access permissions
CREATE TABLE repository_access (
    id SERIAL PRIMARY KEY,
    repository_id INTEGER REFERENCES github_repositories(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    access_level VARCHAR(20) NOT NULL, -- admin, write, read
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(repository_id, user_id)
);

-- Code authentication tokens
-- Used for secure access to repositories and actions
CREATE TABLE auth_tokens (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(256) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Review management
CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'approved', 'changes_requested')),
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    creator_id INTEGER REFERENCES users(id) ON DELETE CASCADE,

    
    -- GitHub integration fields
    repository_id INTEGER REFERENCES github_repositories(id) ON DELETE SET NULL,
    github_pr_number INTEGER,
    github_pr_url TEXT,
    commit_hash VARCHAR(40),
    branch_name VARCHAR(100),
    base_branch VARCHAR(100) DEFAULT 'main',
    push_event_id TEXT, -- GitHub push event ID
    
    -- Review metadata
    auto_created BOOLEAN DEFAULT FALSE, -- Created automatically from push
    requires_approval BOOLEAN DEFAULT TRUE,
    required_approvals INTEGER DEFAULT 1,
    current_approvals INTEGER DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP, -- When it got approved

    -- Constraints
    CONSTRAINT valid_approvals CHECK (current_approvals <= required_approvals)
);

-- GitHub push events log
CREATE TABLE github_push_events (
    id SERIAL PRIMARY KEY,
    repository_id INTEGER REFERENCES github_repositories(id),
    event_id TEXT UNIQUE NOT NULL, -- GitHub event ID
    commit_hash VARCHAR(40) NOT NULL,
    branch_name VARCHAR(100) NOT NULL,
    pusher_username VARCHAR(100) NOT NULL,
    commits_count INTEGER NOT NULL,
    files_changed INTEGER NOT NULL,
    review_id INTEGER REFERENCES reviews(id), -- Associated review
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    raw_payload JSONB -- Full GitHub webhook payload
);

CREATE TABLE review_files (
    id SERIAL PRIMARY KEY,
    review_id INTEGER REFERENCES reviews(id) ON DELETE CASCADE,
    filename VARCHAR(500) NOT NULL,
    content TEXT NOT NULL,
    original_content TEXT,
    file_type VARCHAR(50),
    file_size INTEGER,
    lines_added INTEGER DEFAULT 0,
    lines_removed INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Reviewer assignment and invitation system
CREATE TABLE review_participants (
    id SERIAL PRIMARY KEY,
    review_id INTEGER REFERENCES reviews(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL, -- reviewer, author, observer
    status VARCHAR(20) DEFAULT 'invited', -- invited, accepted, declined
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    responded_at TIMESTAMP,
    UNIQUE(review_id, user_id)
);

CREATE TABLE reviewer_invitations (
    id SERIAL PRIMARY KEY,
    review_id INTEGER REFERENCES reviews(id) ON DELETE CASCADE,
    inviter_id INTEGER REFERENCES users(id),
    invitee_email VARCHAR(100) NOT NULL,
    invitation_token VARCHAR(256) UNIQUE NOT NULL,
    message TEXT,
    status VARCHAR(20) DEFAULT 'pending', -- pending, accepted, declined, expired
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    responded_at TIMESTAMP
);

-- Comments and collaboration
CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    review_id INTEGER REFERENCES reviews(id) ON DELETE CASCADE,
    file_id INTEGER REFERENCES review_files(id) ON DELETE CASCADE,
    parent_comment_id INTEGER REFERENCES comments(id),
    line_number INTEGER,
    line_end_number INTEGER, -- for multi-line comments
    content TEXT NOT NULL,
    comment_type VARCHAR(20) DEFAULT 'general', -- general, suggestion, issue, approval
    author_id INTEGER REFERENCES users(id),
    is_resolved BOOLEAN DEFAULT FALSE,
    resolved_by INTEGER REFERENCES users(id),
    resolved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- AI Analysis results
CREATE TABLE analysis_results (
    id SERIAL PRIMARY KEY,
    review_id INTEGER REFERENCES reviews(id) ON DELETE CASCADE,
    file_id INTEGER REFERENCES review_files(id) ON DELETE CASCADE,
    analysis_type VARCHAR(50) NOT NULL, -- security, quality, performance, style
    severity VARCHAR(20) NOT NULL, -- info, warning, error, critical
    rule_id VARCHAR(100),
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    line_number INTEGER,
    line_end_number INTEGER,
    suggested_fix TEXT,
    confidence_score DECIMAL(3,2), -- 0.00 to 1.00
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Real-time collaboration
CREATE TABLE active_sessions (
    id SERIAL PRIMARY KEY,
    review_id INTEGER REFERENCES reviews(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    file_id INTEGER REFERENCES review_files(id),
    cursor_line INTEGER,
    cursor_column INTEGER,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(review_id, user_id)
);

-- Notification system
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    review_id INTEGER REFERENCES reviews(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- comment, mention, assignment, status_change
    title VARCHAR(200) NOT NULL,
    message TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Users table - add role constraint
ALTER TABLE users ADD CONSTRAINT check_user_role 
CHECK (role IN ('admin', 'reviewer', 'developer', 'observer'));

-- Repository access - add access level constraint  
ALTER TABLE repository_access ADD CONSTRAINT check_access_level
CHECK (access_level IN ('admin', 'write', 'read'));

-- Review participants - add role constraint
ALTER TABLE review_participants ADD CONSTRAINT check_participant_role
CHECK (role IN ('reviewer', 'author', 'observer'));

-- Review participants - add status constraint
ALTER TABLE review_participants ADD CONSTRAINT check_participant_status  
CHECK (status IN ('invited', 'accepted', 'declined'));

-- Comments - add type constraint
ALTER TABLE comments ADD CONSTRAINT check_comment_type
CHECK (comment_type IN ('general', 'suggestion', 'issue', 'approval'));

-- Analysis results - add severity constraint
ALTER TABLE analysis_results ADD CONSTRAINT check_analysis_severity
CHECK (severity IN ('info', 'warning', 'error', 'critical'));

ALTER TABLE reviews ADD CONSTRAINT check_github_pr_consistency 
CHECK (
    (github_pr_number IS NULL AND github_pr_url IS NULL) OR 
    (github_pr_number IS NOT NULL AND github_pr_url IS NOT NULL)
);

-- Ensure line numbers are positive
ALTER TABLE comments ADD CONSTRAINT check_positive_line_numbers
CHECK (line_number > 0 AND (line_end_number IS NULL OR line_end_number >= line_number));

ALTER TABLE analysis_results ADD CONSTRAINT check_positive_line_numbers_analysis  
CHECK (line_number > 0 AND (line_end_number IS NULL OR line_end_number >= line_number));

-- Ensure confidence score is valid percentage
ALTER TABLE analysis_results ADD CONSTRAINT check_confidence_score
CHECK (confidence_score >= 0.00 AND confidence_score <= 1.00);

-- Ensure file size is not negative
ALTER TABLE review_files ADD CONSTRAINT check_positive_file_size
CHECK (file_size >= 0);

-- ✅ ESSENTIAL INDEXES
CREATE INDEX idx_reviews_status ON reviews(status);                    -- Filter by pending/approved reviews
CREATE INDEX idx_reviews_creator ON reviews(creator_id);               -- Show user's reviews  
CREATE INDEX idx_reviews_repository ON reviews(repository_id);         -- Repository dashboard
CREATE INDEX idx_reviews_created_at ON reviews(created_at DESC);       -- Recent reviews first

CREATE INDEX idx_review_participants_review ON review_participants(review_id); 
CREATE INDEX idx_review_participants_user ON review_participants(user_id);
CREATE INDEX idx_comments_review ON comments(review_id);
CREATE INDEX idx_comments_file ON comments(file_id);
CREATE INDEX idx_review_files_review ON review_files(review_id);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id) WHERE is_read = false;
CREATE INDEX idx_github_repositories_github_id ON github_repositories(github_repo_id);

-- For common query patterns:
CREATE INDEX idx_reviews_repo_status ON reviews(repository_id, status);
CREATE INDEX idx_comments_review_file ON comments(review_id, file_id);
CREATE INDEX idx_analysis_review_severity ON analysis_results(review_id, severity);
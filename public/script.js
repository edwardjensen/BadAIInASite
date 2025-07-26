class BadAI {
    constructor() {
        this.currentView = 'menu';
        this.currentCategory = null;
        this.currentPrompt = null;
        this.menu = {};
        this.isLocalAI = true;
        this.aiStatus = 'unknown';
        
        this.init();
    }

    // Strip markdown formatting and clean up text
    markdownToHtml(text) {
        return text
            // Remove markdown formatting entirely
            .replace(/\*\*(.*?)\*\*/g, '$1')  // **bold** -> bold
            .replace(/\*(.*?)\*/g, '$1')      // *italic* -> italic
            .replace(/__(.*?)__/g, '$1')      // __underline__ -> underline
            .replace(/_(.*?)_/g, '$1')        // _italic_ -> italic
            // Line breaks
            .replace(/\n/g, '<br>')
            // Remove excessive whitespace
            .replace(/\s+/g, ' ')
            .trim();
    }

    // Sanitize HTML to prevent XSS (basic sanitization)
    sanitizeHtml(html) {
        const div = document.createElement('div');
        div.textContent = html;
        const sanitized = div.innerHTML;
        // Allow only basic formatting tags
        return sanitized
            .replace(/&lt;strong&gt;/g, '<strong>')
            .replace(/&lt;\/strong&gt;/g, '</strong>')
            .replace(/&lt;em&gt;/g, '<em>')
            .replace(/&lt;\/em&gt;/g, '</em>')
            .replace(/&lt;br&gt;/g, '<br>');
    }

    async init() {
        console.log('Initializing BadAI...');
        await this.loadMenu();
        console.log('Menu loaded:', this.menu);
        await this.loadConfig();
        await this.loadVersionInfo();
        this.setupEventListeners();
        this.setupLiveReload();
        this.renderCategories();
        this.checkAIStatus();
    }

    async loadConfig() {
        try {
            const response = await fetch('/api/config');
            this.config = await response.json();
            
            // Apply UI configuration
            document.documentElement.style.setProperty('--response-min-height', `${this.config.ui.response_min_height}px`);
            
            // Set random disclaimer
            this.setRandomDisclaimer();
            
            console.log('Configuration loaded:', this.config);
        } catch (error) {
            console.error('Failed to load configuration:', error);
            this.config = {
                ui: { response_min_height: 120, loading_timeout: 30000 },
                ai_response: { max_tokens: 80, temperature: 0.9 },
                disclaimers: ['⚠️ This is a fun project! AI responses are intentionally bad and should not be taken seriously.']
            };
            this.setRandomDisclaimer();
        }
    }

    async loadMenu() {
        try {
            console.log('Fetching menu from /api/menu...');
            const response = await fetch('/api/menu');
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            this.menu = await response.json();
            console.log('Menu fetched successfully');
        } catch (error) {
            console.error('Failed to load menu:', error);
            this.showError('Failed to load menu. Please refresh the page.');
        }
    }

    async loadVersionInfo() {
        try {
            const response = await fetch('/api/version');
            const versionInfo = await response.json();
            this.displayVersionInfo(versionInfo);
        } catch (error) {
            console.error('Failed to load version info:', error);
            this.displayVersionInfo({
                version: 'unknown',
                commit: 'unknown',
                environment: 'development'
            });
        }
    }

    displayVersionInfo(versionInfo) {
        const versionElement = document.getElementById('version-text');
        if (versionElement) {
            // Remove 'v' prefix if it exists in the version string
            const cleanVersion = versionInfo.version !== 'unknown' 
                ? versionInfo.version.replace(/^v/, '')
                : versionInfo.commit;
            
            const versionText = versionInfo.version !== 'unknown' 
                ? `v${cleanVersion}` 
                : `${cleanVersion} (${versionInfo.environment})`;
            
            // Only show build date for production, nothing extra for development
            const buildInfo = versionInfo.environment === 'production' 
                ? ` • ${versionInfo.buildDate?.split('T')[0] || 'unknown'}`
                : '';
            
            versionElement.textContent = `${versionText}${buildInfo}`;
        }
    }

    setRandomDisclaimer() {
        const disclaimerElement = document.querySelector('.disclaimer p');
        if (disclaimerElement && this.config.disclaimers && this.config.disclaimers.length > 0) {
            const randomIndex = Math.floor(Math.random() * this.config.disclaimers.length);
            disclaimerElement.textContent = this.config.disclaimers[randomIndex];
        }
    }

    setupEventListeners() {
        // AI toggle
        document.getElementById('ai-toggle').addEventListener('click', () => {
            this.toggleAI();
        });

        // Back buttons
        document.getElementById('back-btn').addEventListener('click', () => {
            this.showView('menu');
        });

        document.getElementById('response-back-btn').addEventListener('click', () => {
            this.showView('prompts');
        });

        // Try again button
        document.getElementById('try-again-btn').addEventListener('click', () => {
            this.generateResponse();
        });
    }

    async checkAIStatus() {
        try {
            const response = await fetch('/api/status');
            const status = await response.json();
            this.updateAIStatus(status.localAI, status.status);
        } catch (error) {
            console.error('Failed to check AI status:', error);
            this.updateAIStatus(false, 'error');
        }
    }

    updateAIStatus(isLocalAvailable, status) {
        const statusElement = document.getElementById('ai-status');
        const toggleElement = document.getElementById('ai-toggle');

        if (status === 'error' || !isLocalAvailable) {
            statusElement.className = 'ai-status error';
            if (this.isLocalAI) {
                this.isLocalAI = false;
                toggleElement.textContent = 'OpenRouter AI';
            }
        } else {
            statusElement.className = 'ai-status';
        }

        this.aiStatus = status;
    }

    toggleAI() {
        this.isLocalAI = !this.isLocalAI;
        const toggleElement = document.getElementById('ai-toggle');
        toggleElement.textContent = this.isLocalAI ? 'Local AI' : 'OpenRouter AI';
        this.checkAIStatus();
    }

    showView(view) {
        document.getElementById('menu-view').classList.add('hidden');
        document.getElementById('prompts-view').classList.add('hidden');
        document.getElementById('response-view').classList.add('hidden');

        document.getElementById(`${view}-view`).classList.remove('hidden');
        this.currentView = view;
    }

    renderCategories() {
        const categoriesContainer = document.getElementById('categories');
        categoriesContainer.innerHTML = '';

        // Sort categories alphabetically
        const sortedCategories = Object.keys(this.menu).sort((a, b) => 
            a.localeCompare(b, undefined, { sensitivity: 'base' })
        );

        sortedCategories.forEach(category => {
            const button = document.createElement('button');
            button.className = 'category-btn';
            button.textContent = category;
            button.addEventListener('click', () => {
                this.selectCategory(category);
            });
            categoriesContainer.appendChild(button);
        });
    }

    selectCategory(category) {
        this.currentCategory = category;
        this.renderPrompts(category);
        this.showView('prompts');
        
        document.getElementById('category-title').textContent = category;
    }

    renderPrompts(category) {
        const promptsContainer = document.getElementById('prompts');
        promptsContainer.innerHTML = '';

        // Sort prompts alphabetically
        const sortedPrompts = Object.keys(this.menu[category]).sort((a, b) => 
            a.localeCompare(b, undefined, { sensitivity: 'base' })
        );

        sortedPrompts.forEach(promptName => {
            const button = document.createElement('button');
            button.className = 'prompt-btn';
            button.textContent = promptName;
            button.addEventListener('click', () => {
                this.selectPrompt(promptName);
            });
            promptsContainer.appendChild(button);
        });
    }

    selectPrompt(promptName) {
        this.currentPrompt = promptName;
        this.showView('response');
        this.generateResponse();
    }

    async generateResponse() {
        const loadingElement = document.getElementById('loading');
        const responseElement = document.getElementById('response');
        const tryAgainBtn = document.getElementById('try-again-btn');

        // Show loading
        loadingElement.classList.remove('hidden');
        responseElement.innerHTML = '';
        tryAgainBtn.classList.add('hidden');

        try {
            const prompt = this.menu[this.currentCategory][this.currentPrompt];
            
            const response = await fetch('/api/chat', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    messages: prompt,
                    useLocal: this.isLocalAI
                })
            });

            const data = await response.json();
            
            loadingElement.classList.add('hidden');
            
            if (data.error) {
                this.showError(data.error);
            } else {
                const formattedResponse = this.sanitizeHtml(this.markdownToHtml(data.response));
                responseElement.innerHTML = formattedResponse;
                responseElement.classList.remove('error');
            }
            
            tryAgainBtn.classList.remove('hidden');

        } catch (error) {
            console.error('Failed to generate response:', error);
            loadingElement.classList.add('hidden');
            this.showError('Oops! Even my bad advice generator is broken. How embarrassingly ironic!');
            tryAgainBtn.classList.remove('hidden');
        }
    }

    showError(message) {
        const responseElement = document.getElementById('response');
        responseElement.innerHTML = this.sanitizeHtml(message);
        responseElement.classList.add('error');
    }

    setupLiveReload() {
        // Only enable live reload in development
        if (typeof io === 'undefined') {
            console.log('Socket.IO not available - live reload disabled');
            return;
        }

        console.log('🔄 Setting up live reload client...');
        
        const socket = io();
        
        socket.on('connect', () => {
            console.log('🔌 Connected to live reload server');
        });
        
        socket.on('reload', () => {
            console.log('🔄 Reloading page...');
            window.location.reload();
        });
        
        socket.on('disconnect', () => {
            console.log('🔌 Disconnected from live reload server');
        });
    }
}

// Initialize the app
document.addEventListener('DOMContentLoaded', () => {
    new BadAI();
});
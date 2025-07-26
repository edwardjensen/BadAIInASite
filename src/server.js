require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs').promises;
const ini = require('ini');

class BadAIServer {
    constructor() {
        this.app = express();
        this.menu = {};
        this.config = {};
    }

    async initialize() {
        await this.loadConfig();
        this.setupAIConfiguration();
        this.setupMiddleware();
        this.setupRoutes();
        await this.loadMenu();
    }

    async loadConfig() {
        try {
            const configPath = path.join(__dirname, '../settings.conf');
            const configFile = await fs.readFile(configPath, 'utf8');
            this.config = ini.parse(configFile);
            console.log('Configuration loaded successfully');
        } catch (error) {
            console.error('Failed to load settings.conf, using defaults:', error.message);
            // Set default configuration
            this.config = {
                ai_response: {
                    max_tokens: 80,
                    temperature: 0.9,
                    concise_prompt: 'Be hilariously unhelpful and mischievous! Keep responses concise (under 100 words). Use NO formatting - no markdown, no asterisks, no underscores, just plain text. Be playful, absurd, and funny. Embrace the silly chaos!'
                },
                ui: {
                    response_min_height: 120,
                    loading_timeout: 30000
                },
                server: {
                    default_port: 3000,
                    api_timeout: 30000
                }
            };
        }
    }

    setupAIConfiguration() {
        // Server configuration
        this.port = process.env.PORT || this.config.server.default_port;
        
        // AI configuration
        const lmStudioAddress = process.env.LM_STUDIO_ADDRESS || 'localhost';
        this.lmStudioUrl = process.env.LM_STUDIO_URL || `http://${lmStudioAddress}:1234/v1/chat/completions`;
        this.openRouterUrl = 'https://openrouter.ai/api/v1/chat/completions';
        this.openRouterKey = process.env.OPENROUTER_API_KEY;
    }

    setupMiddleware() {
        this.app.use(cors());
        this.app.use(express.json());
        this.app.use(express.static(path.join(__dirname, '../public')));
    }

    setupRoutes() {
        // Serve menu
        this.app.get('/api/menu', (req, res) => {
            res.json(this.menu);
        });

        // Check AI status
        this.app.get('/api/status', async (req, res) => {
            const localAIStatus = await this.checkLocalAI();
            res.json({
                localAI: localAIStatus,
                status: localAIStatus ? 'connected' : 'error'
            });
        });

        // Get UI configuration
        this.app.get('/api/config', (req, res) => {
            res.json({
                ui: {
                    response_min_height: this.config.ui.response_min_height,
                    loading_timeout: this.config.ui.loading_timeout
                },
                ai_response: {
                    max_tokens: this.config.ai_response.max_tokens,
                    temperature: this.config.ai_response.temperature
                }
            });
        });

        // Chat endpoint
        this.app.post('/api/chat', async (req, res) => {
            try {
                const { messages, useLocal } = req.body;
                
                if (!messages || !Array.isArray(messages)) {
                    return res.status(400).json({ error: 'Invalid messages format' });
                }

                let response;
                if (useLocal) {
                    response = await this.queryLocalAI(messages);
                } else {
                    response = await this.queryOpenRouter(messages);
                }

                res.json({ response });
            } catch (error) {
                console.error('Chat error:', error);
                res.status(500).json({ 
                    error: 'Something went wrong! Even my errors are bad at being helpful.' 
                });
            }
        });

        // Health check
        this.app.get('/health', (req, res) => {
            res.json({ status: 'ok', timestamp: new Date().toISOString() });
        });
    }

    async loadMenu() {
        try {
            const menuPath = path.join(__dirname, '../menu.json');
            const menuData = await fs.readFile(menuPath, 'utf8');
            this.menu = JSON.parse(menuData);
            console.log('Menu loaded successfully');
        } catch (error) {
            console.error('Failed to load menu:', error);
            this.menu = {};
        }
    }

    async checkLocalAI() {
        try {
            const response = await fetch(this.lmStudioUrl.replace('/chat/completions', '/models'), {
                method: 'GET',
                timeout: 5000
            });
            return response.ok;
        } catch (error) {
            console.log('Local AI not available:', error.message);
            return false;
        }
    }

    async queryLocalAI(messages) {
        try {
            const response = await fetch(this.lmStudioUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    model: 'local-model',
                    messages: [...messages, {
                        role: 'system', 
                        content: this.config.ai_response.concise_prompt
                    }],
                    max_tokens: parseInt(this.config.ai_response.max_tokens),
                    temperature: parseFloat(this.config.ai_response.temperature),
                    stream: false
                }),
                timeout: this.config.server.api_timeout
            });

            if (!response.ok) {
                throw new Error(`Local AI request failed: ${response.status}`);
            }

            const data = await response.json();
            return data.choices[0].message.content.trim();
        } catch (error) {
            console.error('Local AI error:', error);
            throw new Error('Local AI is being particularly unhelpful today. Try OpenRouter instead!');
        }
    }

    async queryOpenRouter(messages) {
        if (!this.openRouterKey) {
            throw new Error('OpenRouter API key not configured. Set OPENROUTER_API_KEY environment variable.');
        }

        try {
            const response = await fetch(this.openRouterUrl, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${this.openRouterKey}`,
                    'Content-Type': 'application/json',
                    'HTTP-Referer': 'https://badaiinasite.local',
                    'X-Title': 'Bad AI In A Site'
                },
                body: JSON.stringify({
                    model: 'google/gemma-2-9b-it:free',
                    messages: [...messages, {
                        role: 'system', 
                        content: this.config.ai_response.concise_prompt
                    }],
                    max_tokens: parseInt(this.config.ai_response.max_tokens),
                    temperature: parseFloat(this.config.ai_response.temperature),
                    stream: false
                }),
                timeout: this.config.server.api_timeout
            });

            if (!response.ok) {
                const errorData = await response.json().catch(() => ({}));
                throw new Error(`OpenRouter API error: ${response.status} - ${errorData.error?.message || 'Unknown error'}`);
            }

            const data = await response.json();
            return data.choices[0].message.content.trim();
        } catch (error) {
            console.error('OpenRouter error:', error);
            throw new Error('OpenRouter is also being unhelpful. The bad advice conspiracy runs deep!');
        }
    }

    async start() {
        await this.initialize();
        
        // Use localhost for development, 0.0.0.0 for production
        const bindAddress = process.env.NODE_ENV === 'production' ? '0.0.0.0' : '127.0.0.1';
        
        this.app.listen(this.port, bindAddress, () => {
            console.log(`🤖 Bad AI In A Site server running on port ${this.port}`);
            console.log(`📱 Open http://localhost:${this.port} to access the site`);
            console.log(`⚙️  Max tokens: ${this.config.ai_response.max_tokens}, Temperature: ${this.config.ai_response.temperature}`);
            
            // Check AI status on startup
            this.checkLocalAI().then(available => {
                console.log(`🧠 Local AI status: ${available ? 'Available' : 'Not available'}`);
                console.log(`🔑 OpenRouter API: ${this.openRouterKey ? 'Configured' : 'Not configured'}`);
            });
        });
    }
}

// Add fetch polyfill for Node.js
if (!global.fetch) {
    global.fetch = require('node-fetch');
}

// Start the server
const server = new BadAIServer();
server.start().catch(error => {
    console.error('Failed to start server:', error);
    process.exit(1);
});
/**
 * Graph Users Service
 * Fetches users from Microsoft Graph API
 */

const { ConfidentialClientApplication } = require('@azure/msal-node');
const config = require('../../config/default');

class GraphUsersService {
    constructor() {
        this.msalClient = new ConfidentialClientApplication({
            auth: {
                clientId: config.azure.clientId,
                clientSecret: config.azure.clientSecret,
                authority: config.azure.authority
            }
        });
    }

    async getUsers() {
        try {
            const tokenResponse = await this.msalClient.acquireTokenByClientCredential({
                scopes: ['https://graph.microsoft.com/.default']
            });

            const response = await fetch('https://graph.microsoft.com/v1.0/users', {
                headers: {
                    'Authorization': `Bearer ${tokenResponse.accessToken}`
                }
            });

            const data = await response.json();
            return data.value || [];
        } catch (error) {
            console.error('[GRAPH] Error fetching users:', error);
            return [];
        }
    }
}

module.exports = GraphUsersService;

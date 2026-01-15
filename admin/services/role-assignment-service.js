/**
 * Role Assignment Service
 * Handles user role and approval management
 */

const sql = require('mssql');
const config = require('../../config/default');

class RoleAssignmentService {
    static async getAllUsers() {
        const pool = await sql.connect(config.database);
        const result = await pool.request().query(`
            SELECT id, azure_id, email, display_name, role, status, created_at, last_login
            FROM users
            ORDER BY created_at DESC
        `);
        return result.recordset;
    }

    static async updateUser(userId, updateData) {
        const pool = await sql.connect(config.database);
        
        const updates = [];
        const request = pool.request().input('userId', sql.Int, userId);
        
        if (updateData.role !== undefined) {
            updates.push('role = @role');
            request.input('role', sql.NVarChar, updateData.role);
        }
        if (updateData.display_name !== undefined) {
            updates.push('display_name = @display_name');
            request.input('display_name', sql.NVarChar, updateData.display_name);
        }
        if (updateData.status !== undefined) {
            updates.push('status = @status');
            request.input('status', sql.NVarChar, updateData.status);
        }
        
        if (updates.length === 0) {
            return await this.getUserById(userId);
        }
        
        await request.query(`
            UPDATE users 
            SET ${updates.join(', ')}, updated_at = GETDATE()
            WHERE id = @userId
        `);
        
        return await this.getUserById(userId);
    }

    static async getUserById(userId) {
        const pool = await sql.connect(config.database);
        const result = await pool.request()
            .input('userId', sql.Int, userId)
            .query('SELECT * FROM users WHERE id = @userId');
        return result.recordset[0];
    }

    static async updateUserRole(userId, newRole) {
        const pool = await sql.connect(config.database);
        
        const status = newRole === 'Pending' ? 'pending' : 'active';
        
        await pool.request()
            .input('userId', sql.Int, userId)
            .input('role', sql.NVarChar, newRole)
            .input('status', sql.NVarChar, status)
            .query(`
                UPDATE users 
                SET role = @role, status = @status, updated_at = GETDATE()
                WHERE id = @userId
            `);
        
        return { success: true };
    }

    static async updateUserStatus(userId, isActive) {
        const pool = await sql.connect(config.database);
        const status = isActive ? 'active' : 'inactive';
        
        await pool.request()
            .input('userId', sql.Int, userId)
            .input('status', sql.NVarChar, status)
            .query(`
                UPDATE users 
                SET status = @status, updated_at = GETDATE()
                WHERE id = @userId
            `);
        
        return await this.getUserById(userId);
    }

    static async approveUser(userId, role = 'Auditor') {
        return this.updateUserRole(userId, role);
    }

    static async rejectUser(userId) {
        const pool = await sql.connect(config.database);
        
        await pool.request()
            .input('userId', sql.Int, userId)
            .query(`
                UPDATE users 
                SET status = 'rejected', updated_at = GETDATE()
                WHERE id = @userId
            `);
        
        return { success: true };
    }

    static async syncUsersFromGraph(graphUsers) {
        const pool = await sql.connect(config.database);
        let newUsers = 0;
        let updatedUsers = 0;

        for (const graphUser of graphUsers) {
            // Skip users without email
            if (!graphUser.mail && !graphUser.userPrincipalName) continue;
            
            const email = graphUser.mail || graphUser.userPrincipalName;
            const displayName = graphUser.displayName || email.split('@')[0];
            const azureId = graphUser.id;

            // Check if user exists
            const existing = await pool.request()
                .input('email', sql.NVarChar, email)
                .query('SELECT id FROM users WHERE email = @email');

            if (existing.recordset.length > 0) {
                // Update existing user
                await pool.request()
                    .input('email', sql.NVarChar, email)
                    .input('displayName', sql.NVarChar, displayName)
                    .input('azureId', sql.NVarChar, azureId)
                    .query(`
                        UPDATE users 
                        SET display_name = @displayName, azure_id = @azureId, updated_at = GETDATE()
                        WHERE email = @email
                    `);
                updatedUsers++;
            } else {
                // Insert new user with Pending role
                await pool.request()
                    .input('email', sql.NVarChar, email)
                    .input('displayName', sql.NVarChar, displayName)
                    .input('azureId', sql.NVarChar, azureId)
                    .query(`
                        INSERT INTO users (email, display_name, azure_id, role, status, created_at)
                        VALUES (@email, @displayName, @azureId, 'Pending', 'pending', GETDATE())
                    `);
                newUsers++;
            }
        }

        return { newUsers, updatedUsers };
    }

    static async logAction(userId, action, details) {
        try {
            const pool = await sql.connect(config.database);
            await pool.request()
                .input('userId', sql.Int, userId)
                .input('action', sql.NVarChar, action)
                .input('details', sql.NVarChar, JSON.stringify(details))
                .query(`
                    INSERT INTO audit_logs (user_id, action, details, created_at)
                    VALUES (@userId, @action, @details, GETDATE())
                `);
        } catch (error) {
            // Log error but don't fail the main operation
            console.error('[AUDIT] Error logging action:', error.message);
        }
    }
}

module.exports = RoleAssignmentService;

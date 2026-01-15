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

    static async updateUserRole(userId, newRole) {
        const pool = await sql.connect(config.database);
        
        const status = newRole === 'pending' ? 'pending_approval' : 'approved';
        
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

    static async approveUser(userId, role = 'auditor') {
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
}

module.exports = RoleAssignmentService;

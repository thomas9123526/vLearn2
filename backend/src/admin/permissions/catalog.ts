export type PermissionCategory = 'content' | 'users' | 'analytics' | 'system' | 'admin';

export interface PermissionDef {
  key: string;
  category: PermissionCategory;
  description: string;
  grantable_to_subadmin: boolean;
  implies?: string[];
}

export const PERMISSION_CATALOG: PermissionDef[] = [
  // Content
  { key: 'scenarios.view',         category: 'content',  description: 'View all scenarios including drafts and archived',                grantable_to_subadmin: true },
  { key: 'scenarios.edit',         category: 'content',  description: 'Create, update, publish, archive scenarios',                       grantable_to_subadmin: true, implies: ['scenarios.view'] },
  { key: 'scenarios.delete',       category: 'content',  description: 'Permanently delete scenarios',                                     grantable_to_subadmin: true, implies: ['scenarios.edit'] },
  { key: 'scenarios.upload_image', category: 'content',  description: 'Upload hero images for scenarios',                                 grantable_to_subadmin: true, implies: ['scenarios.edit'] },
  { key: 'courses.view',           category: 'content',  description: 'View all courses',                                                 grantable_to_subadmin: true },
  { key: 'courses.edit',           category: 'content',  description: 'Create, update, publish, archive courses',                         grantable_to_subadmin: true, implies: ['courses.view'] },
  { key: 'courses.delete',         category: 'content',  description: 'Permanently delete courses',                                       grantable_to_subadmin: true, implies: ['courses.edit'] },
  { key: 'achievements.view',      category: 'content',  description: 'View all achievements',                                            grantable_to_subadmin: true },
  { key: 'achievements.edit',      category: 'content',  description: 'Create and update achievements',                                   grantable_to_subadmin: true, implies: ['achievements.view'] },
  { key: 'achievements.grant',     category: 'content',  description: 'Manually grant achievements to users',                             grantable_to_subadmin: true },
  { key: 'personas.edit',          category: 'content',  description: 'Edit persona settings and portraits',                              grantable_to_subadmin: true },
  { key: 'wordlist.edit',          category: 'content',  description: 'Edit the profanity wordlist (custom.json)',                        grantable_to_subadmin: true },

  // Users
  { key: 'users.view',                    category: 'users', description: 'List users and view basic profiles',                          grantable_to_subadmin: true },
  { key: 'users.view_progress',           category: 'users', description: 'View user progress, scores, and skill trends',                grantable_to_subadmin: true,  implies: ['users.view'] },
  { key: 'users.view_sessions',           category: 'users', description: 'View user session history without transcripts',               grantable_to_subadmin: true,  implies: ['users.view'] },
  { key: 'users.view_violations',         category: 'users', description: 'View guard violations (severity and matched terms only)',     grantable_to_subadmin: true,  implies: ['users.view'] },
  { key: 'users.view_violations_content', category: 'users', description: 'View full user input flagged by the content guard',           grantable_to_subadmin: false, implies: ['users.view_violations'] },
  { key: 'users.view_transcripts',        category: 'users', description: 'View full conversation transcripts (privacy-sensitive)',      grantable_to_subadmin: false, implies: ['users.view_sessions'] },
  { key: 'users.edit',                    category: 'users', description: 'Edit user profile fields',                                    grantable_to_subadmin: true,  implies: ['users.view'] },
  { key: 'users.edit_role',               category: 'users', description: "Change a user's role",                                        grantable_to_subadmin: false, implies: ['users.edit'] },
  { key: 'users.edit_level',              category: 'users', description: "Manually correct a user's English level or XP",               grantable_to_subadmin: false, implies: ['users.edit'] },
  { key: 'users.suspend',                 category: 'users', description: 'Suspend and restore users',                                   grantable_to_subadmin: true,  implies: ['users.view'] },
  { key: 'users.delete',                  category: 'users', description: 'Soft-delete users',                                           grantable_to_subadmin: false, implies: ['users.view'] },

  // Analytics
  { key: 'stats.view',         category: 'analytics', description: 'View the admin stats dashboard',          grantable_to_subadmin: true },
  { key: 'leaderboard.view',   category: 'analytics', description: 'View user leaderboards',                  grantable_to_subadmin: true },
  { key: 'audit.view',         category: 'analytics', description: 'Search and export the admin audit log',   grantable_to_subadmin: true },

  // System
  { key: 'config.view',        category: 'system', description: 'View remote-config / visibility flags',      grantable_to_subadmin: true },
  { key: 'config.edit',        category: 'system', description: 'Modify remote-config / visibility flags',    grantable_to_subadmin: true, implies: ['config.view'] },

  // Admin self-management (never grantable)
  { key: 'admins.view',              category: 'admin', description: 'List sub-admins and their permissions',     grantable_to_subadmin: false },
  { key: 'admins.create',            category: 'admin', description: 'Create new sub-admin accounts',             grantable_to_subadmin: false },
  { key: 'admins.suspend',           category: 'admin', description: 'Suspend or restore sub-admins',             grantable_to_subadmin: false },
  { key: 'admins.delete',            category: 'admin', description: 'Soft-delete sub-admin accounts',            grantable_to_subadmin: false },
  { key: 'admins.grant_permissions', category: 'admin', description: 'Grant or revoke permissions to sub-admins', grantable_to_subadmin: false },
  { key: 'superadmin.transfer',      category: 'admin', description: 'Transfer the superadmin role',              grantable_to_subadmin: false },
];

export const PERMISSION_KEYS = new Set(PERMISSION_CATALOG.map((p) => p.key));
export const GRANTABLE_PERMISSION_KEYS = new Set(
  PERMISSION_CATALOG.filter((p) => p.grantable_to_subadmin).map((p) => p.key),
);

'use client';

import { Card, CardContent } from '@/components/ui/card';

export default function AuditPage() {
  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-lg font-semibold">Audit log</h2>
        <p className="text-sm text-muted-foreground">
          Records every admin action against application or admin data.
        </p>
      </div>
      <Card>
        <CardContent className="py-8 text-center text-sm text-muted-foreground">
          The <code>admin_audit_log</code> table already exists in the DB,
          but no <code>/admin/audit</code> endpoint reads it yet. When that
          ships, this page will paginate with filters by actor / action /
          target / date range.
        </CardContent>
      </Card>
    </div>
  );
}

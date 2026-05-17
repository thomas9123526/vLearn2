'use client';

import { Card, CardContent } from '@/components/ui/card';

export default function UsersPage() {
  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-lg font-semibold">Users</h2>
        <p className="text-sm text-muted-foreground">
          Application users (Flutter sign-ups) live in the <code>users</code>{' '}
          table.
        </p>
      </div>
      <Card>
        <CardContent className="py-8 text-center text-sm text-muted-foreground">
          The <code>/admin/users</code> backend endpoint hasn&apos;t been built
          yet. Once it ships, this page will show a paginated list with search
          by email/displayName, plus suspend / restore / delete actions.
        </CardContent>
      </Card>
    </div>
  );
}

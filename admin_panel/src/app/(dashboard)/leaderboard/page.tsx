'use client';

import { Card, CardContent } from '@/components/ui/card';

export default function LeaderboardPage() {
  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-lg font-semibold">Leaderboard</h2>
        <p className="text-sm text-muted-foreground">
          Top users by XP / streak / minutes-spoken.
        </p>
      </div>
      <Card>
        <CardContent className="py-8 text-center text-sm text-muted-foreground">
          The leaderboard endpoint isn&apos;t built yet. Once
          <code> /admin/leaderboard</code> exists, this page will show the
          top N users with metric tabs (XP, streak, minutes) and CSV export.
        </CardContent>
      </Card>
    </div>
  );
}

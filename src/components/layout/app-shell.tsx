import { Sidebar } from "./sidebar";
import type { Profile } from "@/types/database";

interface AppShellProps {
  children: React.ReactNode;
  profile: Profile | null;
}

export function AppShell({ children, profile }: AppShellProps) {
  return (
    <div className="min-h-screen bg-navy-900">
      <Sidebar profile={profile} />
      <main className="ml-64 min-h-screen p-8">{children}</main>
    </div>
  );
}

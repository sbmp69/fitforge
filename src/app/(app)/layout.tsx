import { AppShell } from "@/components/layout/app-shell";
import { getProfile } from "@/lib/auth";

export default async function AppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const profile = await getProfile();

  return <AppShell profile={profile}>{children}</AppShell>;
}

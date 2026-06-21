import { TailorShell } from "@/components/TailorShell";
import { RequireRole } from "@/components/RequireRole";

export default function TailorLayout({ children }: { children: React.ReactNode }) {
  return (
    <RequireRole role="tailor">
      <TailorShell>{children}</TailorShell>
    </RequireRole>
  );
}

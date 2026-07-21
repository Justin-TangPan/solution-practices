import { Dashboard } from "@/components/dashboard"
import { getWorkbenchSnapshot } from "@/lib/workbench"

export default function Home() {
  return <Dashboard snapshot={getWorkbenchSnapshot()} />
}

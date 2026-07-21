import { ArchitectureWorkspace } from "@/components/architecture-workspace"
import { getWorkbenchSnapshot } from "@/lib/workbench"

export default function WorkspacePage() {
  return <ArchitectureWorkspace snapshot={getWorkbenchSnapshot()} />
}

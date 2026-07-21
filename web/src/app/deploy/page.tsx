import { DeliveryReadiness } from "@/components/delivery-readiness"
import { getWorkbenchSnapshot } from "@/lib/workbench"

export default function DeployPage() {
  return <DeliveryReadiness snapshot={getWorkbenchSnapshot()} />
}

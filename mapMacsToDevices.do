//@context: taskContext()

// Maps the lab mesh MACs to friendly names + role (Controller / Extender) and prints
// the backhaul topology with names instead of raw MACs.
//
// Every device exposes three MACs: br-lan (device identity / DataElements Device.ID),
// 5GHz radio and 6GHz radio. All of them are indexed here so a hit on any interface resolves.
// Value format is "NAME/interface" — Dolang has no top-level def, so one flat map + splitBy
// is cheaper than keeping three parallel maps in sync.
val macToDevice = Map(
  // MIREK (Controller)
  "00:03:7f:9a:98:f4" -> "MIREK/br-lan",
  "00:03:7f:9a:98:f8" -> "MIREK/5g",
  "00:03:7f:9a:98:f9" -> "MIREK/6g",
  // MIRABELA (Extender)
  "00:03:7f:fe:ec:86" -> "MIRABELA/br-lan",
  "00:03:7f:fe:ec:8c" -> "MIRABELA/5g",
  "00:03:7f:fe:ec:8d" -> "MIRABELA/6g",
  // MIROSŁAWA (Extender)
  "00:03:7f:eb:c3:48" -> "MIROSLAWA/br-lan",
  "00:03:7f:eb:c3:4c" -> "MIROSLAWA/5g",
  "00:03:7f:eb:c3:4d" -> "MIROSLAWA/6g",
  // MIRANDA (Controller) — radios use the locally-administered 02: prefix.
  // NOTE: 5g reads 19:98:e6 in the notes while br-lan/6g read 19:96:xx — kept verbatim,
  // worth re-checking on the device in case it is a typo for 02:03:7f:19:96:e6.
  "00:03:7f:19:96:e3" -> "MIRANDA/br-lan",
  "02:03:7f:19:98:e6" -> "MIRANDA/5g",
  "02:03:7f:19:96:e7" -> "MIRANDA/6g",
)

val nameToRole = Map(
  "MIREK"     -> "Controller",
  "MIRANDA"   -> "Controller",
  "MIRABELA"  -> "Extender",
  "MIROSLAWA" -> "Extender",
)

val UNKNOWN = "UNKNOWN/?"

log.info("=== known MACs ===")
macToDevice.toSeq.sortBy((mac, label) => label).foreach { (mac, label) =>
  val name = label.splitBy("/").get(0)
  log.info("$mac  ${nameToRole.getOr(name, "Unknown")}  $label")
}

// --- live topology -----------------------------------------------------------------------

val controllerId = ldm.root.WiFi.DataElements.Network.ControllerID.get().toLower ? ""
val controllerLabel = macToDevice.getOr(controllerId, UNKNOWN)
log.info("=== network ControllerID: $controllerId ($controllerLabel) ===")

val backhaulKeys = ldm.root.WiFi.DataElements.Network.Device.any.MultiAPDevice.Backhaul.keys
  .flatMap(k => Seq(k.MACAddress, k.BackhaulDeviceID, k.BackhaulMACAddress, k.LinkType))
val backhaul = ldm.getAll(backhaulKeys, ignoreFaults = true)

log.info("=== backhaul ===")
backhaulKeys.map(k => k.parent).toSeq.distinct.foreach { bh =>
  val mac       = backhaul.getOr(bh.MACAddress, "").toLower
  val parentMac = backhaul.getOr(bh.BackhaulMACAddress, "").toLower
  val parentId  = backhaul.getOr(bh.BackhaulDeviceID, "").toLower
  val linkType  = backhaul.getOr(bh.LinkType, "")

  val label       = macToDevice.getOr(mac, UNKNOWN)
  val name        = label.splitBy("/").get(0)
  val role        = nameToRole.getOr(name, "Unknown")
  val parentLabel = macToDevice.getOr(parentMac, macToDevice.getOr(parentId, UNKNOWN))
  val parentName  = parentLabel.splitBy("/").get(0)
  val parentRole  = nameToRole.getOr(parentName, "Unknown")

  log.info("$name ($role) $label $mac  --[$linkType]-->  $parentName ($parentRole) $parentLabel $parentMac")

  if (label == UNKNOWN && mac != "") log.warn("MAC $mac not in inventory (device $bh)")
  if (parentLabel == UNKNOWN && parentMac != "") log.warn("backhaul MAC $parentMac not in inventory (device $bh)")
}

finish("SUCCESS", "MAC -> name/role mapping logged")

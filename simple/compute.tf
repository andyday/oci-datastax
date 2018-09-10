resource "oci_core_instance" "DSE_OPSC" {
  provider            = "oci.phx"
  depends_on          = ["oci_core_subnet.DataStax_PublicSubnet_AD_PHX"]
  availability_domain = "${lookup(data.oci_identity_availability_domains.PHX_ADs.availability_domains[0],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "OPSC_AD_1-0"
  image               = "${lookup(data.oci_core_images.OLImageOCID_PHX.images[0], "id")}"
  shape               = "${var.OPSC_Shape}"
  subnet_id           = "${oci_core_subnet.DataStax_PublicSubnet_AD_PHX.0.id}"

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"

    user_data = "${base64encode(format("%s %s %s %s %s %s %s %s %s\n",
           "./userdata/opscenter.sh",
           "${var.DSE_Cluster_Name}",
           "${var.DSE_Cluster_Topology_PHX_Region["AD1_Count"] +
              var.DSE_Cluster_Topology_PHX_Region["AD2_Count"] +
              var.DSE_Cluster_Topology_PHX_Region["AD3_Count"] +
              var.DSE_Cluster_Topology_IAD_Region["AD1_Count"] +
              var.DSE_Cluster_Topology_IAD_Region["AD2_Count"] +
              var.DSE_Cluster_Topology_IAD_Region["AD3_Count"]}",
           "${length(var.regions)}",
           "${var.host_user_name}",
           "${var.DataStax_Academy_Creds["username"]}",
           "${var.DataStax_Academy_Creds["password"]}",
           "${var.Cassandra_DB_User_Password}",
           "${var.OpsCenter_Admin_Password}"
        ))}"
  }
}

resource "oci_core_instance" "DSE_Node_PHX_0" {
  provider            = "oci.phx"
  depends_on          = ["oci_core_instance.DSE_OPSC"]
  availability_domain = "${lookup(data.oci_identity_availability_domains.PHX_ADs.availability_domains[0],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "${format("DSE_AD_PHX_1-%d", count.index)}"
  image               = "${lookup(data.oci_core_images.OLImageOCID_PHX.images[0], "id")}"
  shape               = "${var.DSE_Shape}"
  subnet_id           = "${oci_core_subnet.DataStax_PublicSubnet_AD_PHX.0.id}"
  count               = "${var.DSE_Cluster_Topology_PHX_Region["AD1_Count"]}"

  metadata {
    ssh_authorized_keys = "${var.ssh_public_key}"

    user_data = "${base64encode(format("%s %s %s %s\n",
           "./userdata/node.sh",
           "${data.oci_core_vnic.DSE_OPSC_Vnic.public_ip_address}",
           "${var.DSE_Cluster_Name}",
           "us-phoenix-1"
        ))}"
  }
}
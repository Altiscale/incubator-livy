artifacts builderVersion: "1.1", {

  group "com.sap.bds.ats-altiscale", {

    artifact "livy", {
      file "$gendir/src/livy_rpmbuild/rpm/alti-livy-0.6.1.rpm"
    }
  }
}

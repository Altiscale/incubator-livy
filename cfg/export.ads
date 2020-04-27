artifacts builderVersion: "1.1", {

  group "com.sap.bds.ats-altiscale", {

    artifact "livy", {
      file "$gendir/src/livy_rpmbuild/rpm/alti-livy-0.7.0.rpm"
    }
  }
}

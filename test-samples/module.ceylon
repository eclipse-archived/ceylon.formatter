"Test samples for the ceylon formatter"
module testSamples nameSpace:"group":"artifact":"classifier" "1.0.0" {
    value javaVersion = "7";
    shared import java.base javaVersion;
    import "ceylon.math" "1.0.0";
    value commonsCodecVersion = "1.4";
    import maven:"commons-codec:commons-codec" commonsCodecVersion;
    import maven:"commons-codec":"commons-codec":"classifier" commonsCodecVersion;
}

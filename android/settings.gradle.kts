pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        // Wise SDK (com.wise.sdk:core) and the pinned Zoom SDK it depends on.
        maven { url = uri("https://wise-maven.s3.ap-south-1.amazonaws.com/android/releases") }
    }
}
rootProject.name = "WiseSample"
include(":app")

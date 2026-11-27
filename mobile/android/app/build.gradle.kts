plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Credenciales de firma de release: android/key.properties (no versionado).
// Si el archivo no existe, se firma con la llave de debug para no romper `flutter run`.
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    namespace = "com.jlaburto.citurno"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.jlaburto.citurno"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Sin credenciales el release queda sin firmar; la compilación
            // falla más abajo antes de poder generar nada publicable.
            if (hasReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }

    // Flavors: dev (pruebas) y prod (Google Play).
    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "Citurno Dev")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "Citurno")
        }
    }
}

flutter {
    source = "../.."
}

// Un release sin key.properties NO debe compilarse: antes se firmaba en silencio
// con la llave de debug, Play lo rechaza y la huella de firma queda inservible
// para futuras actualizaciones. El fallo se dispara solo al compilar un release,
// así que `flutter run` en debug sigue funcionando sin keystore.
if (!hasReleaseKeystore) {
    tasks.configureEach {
        val buildsRelease = name.contains("Release") &&
            (name.startsWith("bundle") || name.startsWith("assemble") ||
                name.startsWith("package"))
        if (buildsRelease) {
            doFirst {
                throw GradleException(
                    "Falta android/key.properties: no se puede firmar el build de " +
                        "release. Consulta docs/play-billing-setup.md para crear el " +
                        "keystore y el archivo de credenciales.",
                )
            }
        }
    }
}

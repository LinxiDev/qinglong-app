import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // Flutter Gradle Plugin 必须放在 Android / Kotlin 插件之后应用
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

fun envOrProp(envKey: String, propKey: String): String? {
    val envVal = System.getenv(envKey)
    if (!envVal.isNullOrBlank()) return envVal
    val propVal = keystoreProperties.getProperty(propKey)
    if (!propVal.isNullOrBlank()) return propVal
    return null
}

val releaseStoreFile = envOrProp("ANDROID_KEYSTORE_PATH", "storeFile")
val releaseStorePassword = envOrProp("ANDROID_KEYSTORE_PASSWORD", "storePassword")
val releaseKeyAlias = envOrProp("ANDROID_KEY_ALIAS", "keyAlias")
val releaseKeyPassword = envOrProp("ANDROID_KEY_PASSWORD", "keyPassword")
val hasReleaseSigning = listOf(
    releaseStoreFile,
    releaseStorePassword,
    releaseKeyAlias,
    releaseKeyPassword,
).all { it != null }

android {
    namespace = "work.newtab.qinglong"
    // permission_handler 13 要求 compileSdk >= 37，这里显式指定
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "work.master.qinglongapp"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
                enableV1Signing = true
                enableV2Signing = true
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    lint {
        // Android Lint 在部分 JDK 上会自身崩溃（CommentDetector 依赖 JDK21 API），
        // release 构建不以 lint 结果作为门禁；代码规范用 flutter analyze 保证
        checkReleaseBuilds = false
        abortOnError = false
    }

    packaging {
        resources {
            excludes += setOf("META-INF/*.kotlin_module", "META-INF/AL2.0", "META-INF/LGPL2.1")
        }
    }
}

flutter {
    source = "../.."
}

// Kotlin 2.x 起 kotlinOptions 已废弃，统一使用 compilerOptions
kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

import java.util.Properties

plugins {
    id("com.android.application")
}

// Thông tin ký APK release đọc từ keystore.properties (không commit, xem README).
val keystoreProps = Properties().apply {
    val f = rootProject.file("keystore.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

fun chuoiBuildConfig(ten: String, macDinh: String): String =
    "\"" + (project.findProperty(ten) as String? ?: macDinh) + "\""

android {
    // Package chứa mã nhóm "gugugaga" (quy định E.4 / C.1 #10).
    namespace = "vn.edu.vhu.ltdd.gugugaga.admin"
    compileSdk = 36

    defaultConfig {
        applicationId = "vn.edu.vhu.ltdd.gugugaga.admin"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "0.1.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    signingConfigs {
        if (keystoreProps.getProperty("storeFile") != null) {
            create("release") {
                storeFile = rootProject.file(keystoreProps.getProperty("storeFile"))
                storePassword = keystoreProps.getProperty("storePassword")
                keyAlias = keystoreProps.getProperty("keyAlias")
                keyPassword = keystoreProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        debug {
            buildConfigField("String", "API_BASE_URL",
                chuoiBuildConfig("ocopApiBaseUrlDebug", "http://10.0.2.2:3000/"))
        }
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            buildConfigField("String", "API_BASE_URL",
                chuoiBuildConfig("ocopApiBaseUrlRelease", "https://ocop-backend.onrender.com/"))
            signingConfigs.findByName("release")?.let { signingConfig = it }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        buildConfig = true
    }
}

dependencies {
    implementation("androidx.appcompat:appcompat:1.7.1")
    implementation("com.google.android.material:material:1.13.0")
    implementation("androidx.constraintlayout:constraintlayout:2.2.1")
    implementation("androidx.recyclerview:recyclerview:1.4.0")
    implementation("androidx.fragment:fragment:1.8.9")
    implementation("androidx.lifecycle:lifecycle-viewmodel:2.9.4")
    implementation("androidx.lifecycle:lifecycle-livedata:2.9.4")

    // Gọi API theo Phụ lục 2 của tài liệu đồ án.
    implementation("com.squareup.retrofit2:retrofit:2.11.0")
    implementation("com.squareup.retrofit2:converter-gson:2.11.0")
    implementation("com.squareup.okhttp3:logging-interceptor:4.12.0")

    testImplementation("junit:junit:4.13.2")
}

// ApiContractTest chỉ chạy khi có OCOP_API_TEST_URL; khai báo làm đầu vào để Gradle
// chạy lại test khi biến này thay đổi thay vì dùng kết quả cũ trong cache.
tasks.withType<Test>().configureEach {
    inputs.property("ocopApiTestUrl", System.getenv("OCOP_API_TEST_URL") ?: "")
}

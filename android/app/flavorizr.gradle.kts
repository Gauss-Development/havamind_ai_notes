import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("environment")

    productFlavors {
        create("development") {
            dimension = "environment"
            applicationId = "com.havamind.app.dev"
            resValue(type = "string", name = "app_name", value = "Hava Mind Dev")
        }
        create("production") {
            dimension = "environment"
            applicationId = "com.havamind.app"
            resValue(type = "string", name = "app_name", value = "Hava Mind")
        }
    }
}
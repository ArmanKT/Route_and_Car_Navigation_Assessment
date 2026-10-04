package com.akt.navigation.route_and_car_navigation

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.net.Uri
import android.os.Looper
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.akt.navigation/location_method"
    private val EVENT_CHANNEL = "com.akt.navigation/location_event"
    private val PERMISSION_REQUEST_CODE = 1001

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private var pendingPermissionResult: MethodChannel.Result? = null

    // Continuous location stream
    private var locationCallback: LocationCallback? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)

        // MethodChannel setup
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkPermission" -> handleCheckPermission(result)
                    "requestPermission" -> handleRequestPermission(result)
                    "isLocationServiceEnabled" -> handleIsLocationServiceEnabled(result)
                    "openAppSettings" -> handleOpenAppSettings(result)
                    "getCurrentLocation" -> handleGetCurrentLocation(result)
                    else -> result.notImplemented()
                }
            }

        // EventChannel setup
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    startLocationUpdates()
                }

                override fun onCancel(arguments: Any?) {
                    stopLocationUpdates()
                    eventSink = null
                }
            })
    }

    private fun handleCheckPermission(result: MethodChannel.Result) {
        val fineLocation = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION
        )
        val coarseLocation = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_COARSE_LOCATION
        )

        if (fineLocation == PackageManager.PERMISSION_GRANTED ||
            coarseLocation == PackageManager.PERMISSION_GRANTED
        ) {
            result.success("granted")
        } else {
            result.success("denied")
        }
    }

    private fun handleRequestPermission(result: MethodChannel.Result) {
        if (hasLocationPermission()) {
            result.success("granted")
            return
        }

        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
            ),
            PERMISSION_REQUEST_CODE
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() &&
                    grantResults.any { it == PackageManager.PERMISSION_GRANTED }

            if (granted) {
                pendingPermissionResult?.success("granted")
            } else {
                val shouldShowRationale = ActivityCompat.shouldShowRequestPermissionRationale(
                    this,
                    Manifest.permission.ACCESS_FINE_LOCATION
                )
                if (!shouldShowRationale) {
                    pendingPermissionResult?.success("permanentlyDenied")
                } else {
                    pendingPermissionResult?.success("denied")
                }
            }
            pendingPermissionResult = null
        }
    }

    private fun handleIsLocationServiceEnabled(result: MethodChannel.Result) {
        val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val isGpsEnabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)
        val isNetworkEnabled = locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        result.success(isGpsEnabled || isNetworkEnabled)
    }

    private fun handleOpenAppSettings(result: MethodChannel.Result) {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("SETTINGS_ERROR", e.localizedMessage, null)
        }
    }

    private fun handleGetCurrentLocation(result: MethodChannel.Result) {
        if (!hasLocationPermission()) {
            result.error(
                "PERMISSION_DENIED",
                "Location permission has not been granted",
                null
            )
            return
        }

        val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val isEnabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        if (!isEnabled) {
            result.error(
                "SERVICES_DISABLED",
                "Device location services are turned off",
                null
            )
            return
        }

        val cts = CancellationTokenSource()

        try {
            fusedLocationClient.getCurrentLocation(
                Priority.PRIORITY_HIGH_ACCURACY,
                cts.token
            ).addOnSuccessListener { location: Location? ->
                if (location != null) {
                    result.success(locationToMap(location))
                } else {
                    // Fallback to last known location if getCurrentLocation returned null
                    fusedLocationClient.lastLocation.addOnSuccessListener { lastLoc: Location? ->
                        if (lastLoc != null) {
                            result.success(locationToMap(lastLoc))
                        } else {
                            result.error(
                                "LOCATION_TIMEOUT",
                                "Unable to acquire location fix within timeout",
                                null
                            )
                        }
                    }.addOnFailureListener { e ->
                        result.error("LOCATION_TIMEOUT", e.localizedMessage, null)
                    }
                }
            }.addOnFailureListener { e ->
                result.error("LOCATION_TIMEOUT", e.localizedMessage, null)
            }
        } catch (e: SecurityException) {
            result.error("PERMISSION_DENIED", e.localizedMessage, null)
        }
    }

    private fun startLocationUpdates() {
        if (!hasLocationPermission()) {
            eventSink?.error("PERMISSION_DENIED", "Location permission denied", null)
            return
        }

        val locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 2000L)
            .setMinUpdateIntervalMillis(1000L)
            .setMinUpdateDistanceMeters(1.0f)
            .build()

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                for (location in result.locations) {
                    eventSink?.success(locationToMap(location))
                }
            }
        }

        try {
            fusedLocationClient.requestLocationUpdates(
                locationRequest,
                locationCallback!!,
                Looper.getMainLooper()
            )
        } catch (e: SecurityException) {
            eventSink?.error("PERMISSION_DENIED", e.localizedMessage, null)
        }
    }

    private fun stopLocationUpdates() {
        locationCallback?.let {
            fusedLocationClient.removeLocationUpdates(it)
            locationCallback = null
        }
    }

    private fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED ||
                ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                ) == PackageManager.PERMISSION_GRANTED
    }

    private fun locationToMap(location: Location): Map<String, Any?> {
        return mapOf(
            "latitude" to location.latitude,
            "longitude" to location.longitude,
            "accuracy" to if (location.hasAccuracy()) location.accuracy.toDouble() else null,
            "bearing" to if (location.hasBearing()) location.bearing.toDouble() else null,
            "speed" to if (location.hasSpeed()) location.speed.toDouble() else null,
            "timestamp" to location.time
        )
    }

    override fun onDestroy() {
        stopLocationUpdates()
        super.onDestroy()
    }
}

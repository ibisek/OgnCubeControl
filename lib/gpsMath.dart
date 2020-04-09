//
// Based on Gpsjava from vfrManual and Outlanded
//

import 'dart:math';

class GpsMath {

/// Longitude and latitude in RADians!
/// @param lat1
/// @param lon1
/// @param lat2
/// @param lon2
/// @return distance between two points in kilometers
	static double getDistanceInKm(double lat1, double lon1, double lat2, double lon2) {
		int R = 6371; // km
		double dist = acos(sin(lat1) * sin(lat2) + cos(lat1) * cos(lat2) * cos(lon2 - lon1)) * R;

		return dist;
	}

	/// Longitude and latitude in RADians!
	/// @param lat1
	/// @param lon1
	/// @param lat2
	/// @param lon2
	/// @return distance between two points in meters
	static double getDistanceInM(double lat1, double lon1, double lat2, double lon2) {
		return getDistanceInKm(lat1, lon1, lat2, lon2) * 1000.0;
	}

	/// Longitude and latitude in RADians!
	/// @param lat1 TO
	/// @param lon1 TO
	/// @param lat2 FROM
	/// @param lon2 FROM
	/// @return bearing in degrees
	static double getBearing(double lat1, double lon1, double lat2, double lon2) {

		double dLon = lon2 - lon1;
		double y = sin(dLon) * cos(lat2);
		double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
		double bearing = atan2(y, x);

		bearing = ((toDegrees(bearing) + 180) % 360);

		return bearing;
	}

	static double toDegrees(double rad) {
		return rad * 180.0 / pi;
	}

	static double toRadians(double deg) {
		return deg * pi / 180.0;
	}

}

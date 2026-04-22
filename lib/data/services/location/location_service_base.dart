import 'package:cloud_firestore/cloud_firestore.dart';

abstract class LocationServiceBase {
  Stream<GeoPoint> get positionStream;
}

//classe astratta per generalizzare un servizio di localizzazione
//permette di switchare tra la posizione simulata e il gps reale

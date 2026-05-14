// lib/data/mock_restaurants.dart
import '../models/restaurant.dart';

const mockRestaurants = <Restaurant>[
  Restaurant(
    id: 'r001',
    name: 'Cafe Um',
    location: 'Cheonan',
    description: 'A cozy brunch cafe in Cheonan.',
    imagePath: 'assets/images/italyjae_1.jpg',
    tags: ['₩₩', 'Brunch', 'Cafe'],
    rawCategory: 'Brunch Cafe',
    lat: 37.5112,
    lng: 127.0592,
  ),
  Restaurant(
    id: 'r002',
    name: 'Rikak Museum Cafe',
    location: 'Cheonan',
    description: 'A cafe inside Rikak Museum with artistic atmosphere.',
    imagePath: 'assets/images/italyjae_1.jpg',
    tags: ['₩₩₩', 'Cafe', 'European'],
    rawCategory: 'Cafe',
    lat: 37.5146,
    lng: 127.0600,
  ),
  Restaurant(
    id: 'r003',
    name: 'Sourdough Pizza Lab',
    location: 'Seoul',
    description: 'Authentic sourdough pizza restaurant.',
    imagePath: 'assets/images/italyjae_1.jpg',
    tags: ['₩₩₩', 'Italian'],
    rawCategory: 'Italian',
    lat: 37.5130,
    lng: 127.0580,
  ),
];
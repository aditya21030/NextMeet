class TripSuggestion {
  final String title;
  final String description;
  final int priceLevel; // 1:$, 2:$$, 3:$$$
  final String vibe; // #Romantic, #Adventure, #Chill
  final String category; // Sightseeing, Food, Stay
  final String photoId; // Unsplash Photo ID
  
  const TripSuggestion(this.title, {
    this.description = "A must-visit spot for your journey.",
    this.priceLevel = 2,
    this.vibe = "#Adventure",
    this.category = "Sightseeing",
    this.photoId = "1548013146-72479768bbaa", // Default Delhi photo
  });

  // High-res optimized image URL
  String get dynamicImageUrl => "https://images.unsplash.com/photo-$photoId?auto=format&fit=crop&q=80&w=1080";
}

class TripData {
  static const Map<String, Map<String, List<TripSuggestion>>> globalSuggestions = {
    'Mumbai': {
      'places': [
        TripSuggestion('Marine Drive', description: 'The famous Queen\'s Necklace for a sunset walk.', priceLevel: 1, vibe: '#Romantic', photoId: '1506461883276-594a12b11ba3'),
        TripSuggestion('Gateway of India', description: 'Iconic historic arch overlooking the Arabian Sea.', priceLevel: 1, vibe: '#Culture', photoId: '1533038590840-34446059d0df'),
        TripSuggestion('Colaba Causeway', description: 'Street shopping and legendary cafes.', priceLevel: 2, vibe: '#Shopping', photoId: '1596484552979-3300f4067f88'),
        TripSuggestion('Elephanta Caves', description: 'Ancient rock-cut temples reachable by ferry.', priceLevel: 1, vibe: '#Adventure', photoId: '1596484552834-0bd1f8a5585b'),
        TripSuggestion('Siddhivinayak Temple', description: 'Spiritual heart of the city.', priceLevel: 1, vibe: '#Spiritual', photoId: '1612450800052-3788f4077694'),
        TripSuggestion('Bandra-Worli Sea Link', description: 'Engineering marvel with stunning city views.', priceLevel: 1, vibe: '#Modern', photoId: '1596484552979-3300f4067f88'),
      ],
      'hotels': [
        TripSuggestion('Taj Mahal Palace', description: 'Living life king size at India\'s finest hotel.', priceLevel: 3, vibe: '#Luxury', category: 'Stay', photoId: '1582719508461-905c673771fd'),
        TripSuggestion('The Oberoi', description: 'Exceptional views and Michelin-standard dining.', priceLevel: 3, vibe: '#FineDining', category: 'Stay', photoId: '1566073771259-6a8506099945'),
        TripSuggestion('Soho House Mumbai', description: 'Artistic club and stay in Juhu.', priceLevel: 3, vibe: '#Creative', category: 'Stay', photoId: '1540541338287-41700207dee6'),
        TripSuggestion('Abode Bombay', description: 'Charming boutique stay near Colaba.', priceLevel: 2, vibe: '#Artist', category: 'Stay', photoId: '1566665797739-1674de7a421a'),
      ],
      'food': [
        TripSuggestion('Leopold Cafe', description: 'Historic traveler haunt with a local vibe.', priceLevel: 2, vibe: '#Historic', category: 'Food', photoId: '1517248135467-4c7edcad34c4'),
        TripSuggestion('Britannia & Co.', description: 'Legendary Parsi food in a heritage setting.', priceLevel: 2, vibe: '#Authentic', category: 'Food', photoId: '1552566629-52989808b464'),
      ],
    },
    'Delhi': {
      'places': [
        TripSuggestion('Qutub Minar', description: 'Marvel at the ancient tallest brick minaret.', priceLevel: 1, vibe: '#Historic', photoId: '1610448107875-10336fc19e91'),
        TripSuggestion('Hauz Khas Village', description: 'Blend of ancient ruins and chic cafes.', priceLevel: 2, vibe: '#Chill', photoId: '1515162305285-0293e4767cc2'),
        TripSuggestion('India Gate Stroll', description: 'A nightly picnic spot for thousand of locals.', priceLevel: 1, vibe: '#Romantic', photoId: '1587474260584-17d1e4223f6e'),
        TripSuggestion('Lotus Temple', description: 'Peace and stunning architecture for quiet afternoons.', priceLevel: 1, vibe: '#Silent', photoId: '1548013146-72479768bbaa'),
        TripSuggestion('Red Fort', description: 'The majestic soul of the Mughal Empire.', priceLevel: 1, vibe: '#Imperial', photoId: '1588506191060-60317e119cf2'),
        TripSuggestion('Akshardham', description: 'World-class spiritual-cultural campus.', priceLevel: 1, vibe: '#Spiritual', photoId: '1622396481328-9b1b78cdd9fd'),
      ],
      'hotels': [
        TripSuggestion('The Lodhi', description: 'Contemporary luxury with private plunge pools.', priceLevel: 3, vibe: '#Executive', category: 'Stay', photoId: '1542314831-068cd1dbfeeb'),
        TripSuggestion('Roseate House', description: 'Art-inspired hospitality near the airport.', priceLevel: 3, vibe: '#Modern', category: 'Stay', photoId: '1618773928121-c32242e8173d'),
        TripSuggestion('ITC Maurya', description: 'Traditional luxury with world-class dining.', priceLevel: 3, vibe: '#Regal', category: 'Stay', photoId: '1566073771259-6a8506099945'),
        TripSuggestion('Haveli Dharampura', description: 'Mughal-era charm in the heart of Old Delhi.', priceLevel: 2, vibe: '#Vintage', category: 'Stay', photoId: '1522771739844-6a9f6d5f14af'),
      ],
      'food': [
        TripSuggestion('Paranthe Wali Gali', description: 'Historic street for world-famous parathas.', priceLevel: 1, vibe: '#Local', category: 'Food', photoId: '1504674900247-0877df9cc836'),
        TripSuggestion('Indian Accent', description: 'A redefined modern Indian culinary journey.', priceLevel: 3, vibe: '#AwardWinning', category: 'Food', photoId: '1514362545857-3bc16c4c7d1b'),
      ],
    },
    'Paris': {
      'places': [
        TripSuggestion('Eiffel Tower', description: 'The iron lady of Paris, spectacular at night.', priceLevel: 2, vibe: '#Iconic', photoId: '1502602898657-3e91760cbb34'),
        TripSuggestion('Louvre Museum', description: 'Home to thousands of years of art history.', priceLevel: 2, vibe: '#Culture', photoId: '1499856871958-5b964754a93c'),
        TripSuggestion('Seine River Cruise', description: 'Experience Paris from the heart of the river.', priceLevel: 2, vibe: '#Romantic', photoId: '1503917988258-f87a78e3c995'),
        TripSuggestion('Montmartre', description: 'Artistic hilltop village with stunning views.', priceLevel: 1, vibe: '#Bohemian', photoId: '1554907984-15263bfd63bd'),
        TripSuggestion('Notre Dame', description: 'Gothic masterpiece of French architecture.', priceLevel: 1, vibe: '#Historic', photoId: '1478147427282-58a87a120781'),
        TripSuggestion('Jardin du Luxembourg', description: 'Stately park perfect for a picnic.', priceLevel: 1, vibe: '#Relaxing', photoId: '1505993597083-3bd19fb75e57'),
      ],
      'hotels': [
        TripSuggestion('The Ritz Paris', description: 'Ultimate luxury in the heart of the city.', priceLevel: 3, vibe: '#Legendary', category: 'Stay', photoId: '1551882547-ff43c33ff783'),
        TripSuggestion('Cozy Marais Airbnb', description: 'Charming local living in the artistic district.', priceLevel: 2, vibe: '#Local', category: 'Stay', photoId: '1522708323590-d2485567253b'),
        TripSuggestion('Hôtel Plaza Athénée', description: 'The most fashionable stay in Paris.', priceLevel: 3, vibe: '#Couture', category: 'Stay', photoId: '1566073771259-6a8506099945'),
      ],
      'food': [
        TripSuggestion('Pink Mamma', description: 'Modern Italian feast with Instagrammable views.', priceLevel: 2, vibe: '#Trendy', category: 'Food', photoId: '1517248135467-4c7edcad34c4'),
        TripSuggestion('L\'As du Fallafel', description: 'The absolute best street food in Paris.', priceLevel: 1, vibe: '#Local', category: 'Food', photoId: '1526367790999-01507244a76d'),
      ],
    },
    'Dubai': {
      'places': [
        TripSuggestion('Burj Khalifa', description: 'Peak of human engineering and city views.', priceLevel: 3, vibe: '#Iconic', photoId: '1582672097782-a042ca575653'),
        TripSuggestion('Dubai Mall', description: 'Worlds largest aquarium and world-class shopping.', priceLevel: 1, vibe: '#Luxury', photoId: '1512453979798-5eaad66f887a'),
        TripSuggestion('Desert Safari', description: 'Classic dune bashing and sunset camp.', priceLevel: 2, vibe: '#Adventure', photoId: '1560965158-b63327f27e57'),
        TripSuggestion('Palm Jumeirah', description: 'Iconic man-made island shaped like a tree.', priceLevel: 2, vibe: '#Modern', photoId: '1528659170-29da143b9d03'),
        TripSuggestion('Dubai Souks', description: 'Vibrant gold and spice markets of Old Dubai.', priceLevel: 1, vibe: '#Local', photoId: '1596484552979-3300f4067f88'),
      ],
      'hotels': [
        TripSuggestion('Burj Al Arab', description: 'Ultra-luxury 7-star sail-shaped icon.', priceLevel: 3, vibe: '#Elite', category: 'Stay', photoId: '1582719508461-905c673771fd'),
        TripSuggestion('Atlantis The Palm', description: 'Ocean-themed resort with an underwater suite.', priceLevel: 3, vibe: '#Adventurous', category: 'Stay', photoId: '1566073771259-6a8506099945'),
        TripSuggestion('Park Hyatt Dubai', description: 'Resort-style luxury overlooking the creek.', priceLevel: 3, vibe: '#Chill', category: 'Stay', photoId: '1542314831-068cd1dbfeeb'),
      ],
      'food': [
        TripSuggestion('Al Fanar Restaurant', description: 'Authentic Emirati flavors from the past.', priceLevel: 2, vibe: '#OldSoul', category: 'Food', photoId: '1552566629-52989808b464'),
        TripSuggestion('Zuma Dubai', description: 'Modern Japanese dining in the heart of DIFC.', priceLevel: 3, vibe: '#Trendy', category: 'Food', photoId: '1514362545857-3bc16c4c7d1b'),
      ],
    },
    'Bali': {
      'places': [
        TripSuggestion('Ubud Rice Terraces', description: 'Iconic lush green stepped rice fields.', priceLevel: 1, vibe: '#Peaceful', photoId: '1537996194471-e657df975ab4'),
        TripSuggestion('Uluwatu Temple', description: 'Sunset clifftop temple with Kecak fire dance.', priceLevel: 1, vibe: '#Spiritual', photoId: '1555400038-63f5ba517a47'),
        TripSuggestion('Nusa Penida Boat Trip', description: 'Dramatic cliffs and crystal clear lagoons.', priceLevel: 2, vibe: '#Adventure', photoId: '1538332576228-eb5b4c4de6ec'),
        TripSuggestion('Seminyak Sunset', description: 'Worlds best beach clubs and orange skies.', priceLevel: 2, vibe: '#Vibrant', photoId: '1518548419970-58e3b4079ab2'),
        TripSuggestion('Monkey Forest', description: 'Ancient temple ruins shared with playful macaques.', priceLevel: 1, vibe: '#Wild', photoId: '1552465011-b4e21bf6e79a'),
      ],
      'hotels': [
        TripSuggestion('Four Seasons Sayan', description: 'Lush valley luxury beyond imagination.', priceLevel: 3, vibe: '#Private', category: 'Stay', photoId: '1540541338287-41700207dee6'),
        TripSuggestion('Luxury Pool Villa', description: 'The absolute Bali sanctuary for couples.', priceLevel: 2, vibe: '#Romantic', category: 'Stay', photoId: '1566665797739-1674de7a421a'),
        TripSuggestion('Como Shambhala', description: 'World-renowned wellness and jungle views.', priceLevel: 3, vibe: '#Wellness', category: 'Stay', photoId: '1542314831-068cd1dbfeeb'),
      ],
      'food': [
        TripSuggestion('The Sayan House', description: 'Dazzling sunset with Japan-meets-Bali tapas.', priceLevel: 2, vibe: '#SunsetView', category: 'Food', photoId: '1517248135467-4c7edcad34c4'),
        TripSuggestion('Motel Mexicola', description: 'The colorful soul of Seminyak nightlife.', priceLevel: 2, vibe: '#Energy', category: 'Food', photoId: '1526367790999-01507244a76d'),
      ],
    },
  };

  static List<String> getCities() {
    return globalSuggestions.keys.toList();
  }

  static Map<String, List<TripSuggestion>> getSuggestionsForCity(String city) {
    // Try exact match first
    if (globalSuggestions.containsKey(city)) return globalSuggestions[city]!;
    
    // Try case-insensitive match
    final key = globalSuggestions.keys.firstWhere(
      (k) => k.toLowerCase() == city.toLowerCase(),
      orElse: () => '',
    );
    
    if (key.isNotEmpty) return globalSuggestions[key]!;
    
    // Fallback logic for "Every City" - Dynamic Suggestions
    return {
      'places': [
        TripSuggestion('Top Attraction in $city', description: 'Discover the hidden beauty of this local spot.', priceLevel: 2, vibe: '#MustSee', photoId: '1467269239215-9296910c8bb1'),
        TripSuggestion('Romantic Local Walk', description: 'The local favorite spot for a evening stroll.', priceLevel: 1, vibe: '#Romantic', photoId: '1501339847244-33b8b60ec8bb'),
        TripSuggestion('Hidden Gem Tour', description: 'Experience the city like a true insider.', priceLevel: 1, vibe: '#Hidden', photoId: '1533152177305-402b8cf4b4f7'),
      ],
      'hotels': [
        TripSuggestion('Luxury Skyline Hotel', description: 'Breathtaking views of the city lights.', priceLevel: 3, vibe: '#HighEnd', category: 'Stay', photoId: '1551882547-ff43c33ff783'),
        TripSuggestion('Boutique Guesthouse', description: 'Warm, local hospitality with modern amenities.', priceLevel: 2, vibe: '#Local', category: 'Stay', photoId: '1522771739844-6a9f6d5f14af'),
      ],
      'transport': [
        TripSuggestion('Local Transit Pass', description: 'Efficient and green way to traverse.', priceLevel: 1, vibe: '#Sustainable', photoId: '1513233810237-789a7ec93ce4'),
      ],
    };
  }
}

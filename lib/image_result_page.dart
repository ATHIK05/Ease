import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'disposal.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ImageResultPage extends StatefulWidget {
  final File image;
  final Map<String, dynamic> descriptionText;

  ImageResultPage({required this.image, required this.descriptionText});

  @override
  _ImageResultPageState createState() => _ImageResultPageState();
}

class _ImageResultPageState extends State<ImageResultPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _responseText = "Select a tab to fetch data";
  List<String> _labels = [];
  bool _isScrolled = false; // Track scroll state
  late ScrollController _scrollController;
  int _count=0;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 3); // Start at Disposal Measures tab
    _extractLabels();
    _fetchData("Disposal Measures"); // Fetch data for the default tab
  }

  void _extractLabels() {
  try {
    print("🔍 Raw JSON Data: ${widget.descriptionText}");

    var labelsRaw = widget.descriptionText["labels"];
    print("📦 Extracted Labels Raw: $labelsRaw");

    if (labelsRaw != null && labelsRaw is List) {
      final labelsList = List<String>.from(labelsRaw);
      setState(() {
        _labels = labelsList.toSet().toList();
        _count = widget.descriptionText["count"] ?? 0;
      });
      print("✅ Final Extracted Labels: $_labels");
    } else {
      print("❌ Error: 'labels' is not a valid list!");
      setState(() {
        _labels = [];
        _count = 0;
        _responseText = "No labels found!";
      });
    }
  } catch (e) {
    print("⚠️ Label Extraction Error: $e");
    setState(() {
      _labels = [];
      _count = 0;
      _responseText = "Error extracting labels.";
    });
  }
  }

  /// Fetch API Key from Firestore document "conversationllama"
  /// The document should have a field named "https://open-ai21.p.rapidapi.com/conversationllama"
  /// whose value is an array of API keys.
  Future<String?> _fetchAPIKey() async {
    try {
      print("🔄 Fetching API Keys from Firestore...");
      DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore.instance
          .collection("company")
          .doc("conversationllama")
          .get();

      // Check if the field with the endpoint as key exists.
      if (doc.exists &&
          doc.data() != null &&
          doc.data()!.containsKey("https://open-ai21.p.rapidapi.com/conversationllama")) {
        List<dynamic> apiKeys = doc.data()!["https://open-ai21.p.rapidapi.com/conversationllama"];

        if (apiKeys.isEmpty) {
          print("❌ No API keys available in Firestore");
          return null;
        }

        // Iterate over each key in the array.
        for (String key in apiKeys) {
          print("🔍 Testing API Key: $key");
          bool success = await _testAPIKey(key);
          if (success) {
            print("✅ API Key is valid: $key");
            return key;
          }
        }
        print("❌ No valid API key found in the provided array.");
      } else {
        print("❌ API Key array not found in Firestore!");
      }
    } catch (e) {
      print("⚠️ Error fetching API Key: $e");
    }
    return null; // Return null if all keys fail
  }

  /// Tests API Key to see if it works using the conversationllama endpoint.
  Future<bool> _testAPIKey(String apiKey) async {
    try {
      var url = Uri.parse("https://open-ai21.p.rapidapi.com/conversationllama");
      var response = await http.post(url, headers: {
        "X-RapidAPI-Key": apiKey,
        "Content-Type": "application/json"
      });

      print("🔍 API Key Test Response: ${response.statusCode}");
      return response.statusCode == 200; // Key is valid if status code is 200
    } catch (e) {
      print("⚠️ Error testing API Key: $e");
      return false;
    }
  }

  /// Fetches data from the conversationllama endpoint using the valid API key.
  Future<void> _fetchData(String query) async {
    if (_labels.isEmpty) {
      print("❌ No labels found, cannot fetch data.");
      setState(() {
        _responseText = "No labels found!";
      });
      return;
    }

    // Fetch user's language from Firestore
    String language = "English";
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      language = userDoc.data()?['language'] ?? "English";
    }

    // Build the query string based on the user's input and language.
    String formattedQuery;
    if (language == "Hindi") {
      if (query == "Product Details") {
        formattedQuery =
            "इन लेबल्स के आधार पर: ${_labels.join(", ")}, उत्पाद की पहचान करें। इसके दैनिक जीवन में महत्व और उपयोगकर्ताओं द्वारा आमतौर पर अनुभव किए जाने वाले तीन प्रमुख लाभ और हानियों को विस्तार से समझाएं।";
      } else if (query == "Environmental Impact") {
        formattedQuery =
            "इन लेबल्स का उपयोग करके: ${_labels.join(", ")}, उत्पाद निर्धारित करें। इसके पर्यावरण पर प्रभाव का विश्लेषण करें, जिसमें पारिस्थितिक तंत्र पर प्रभाव और व्यावहारिक उपयोग शामिल हैं। यदि यह हानिकारक है, तो प्रदूषण को कम करने और स्थिरता को बढ़ावा देने के लिए इसे जिम्मेदारी से पुन: उपयोग या निपटान के यथार्थवादी तरीके सुझाएं। अनावश्यक परिचयात्मक वाक्यांशों से बचें और केवल सामग्री प्रदान करें।";
      } else if (query == "Health Impact") {
        formattedQuery =
            "इन लेबल्स के आधार पर उत्पाद की पहचान करें: ${_labels.join(", ")}. इसके स्वास्थ्य लाभ और संभावित जोखिमों पर चर्चा करें। सुरक्षा, एलर्जी या दीर्घकालिक प्रभावों के बारे में आम चिंताओं को संबोधित करें। अनावश्यक परिचयात्मक वाक्यांशों से बचें और सीधे, स्पष्ट जानकारी प्रदान करें।";
      } else {
        formattedQuery =
            "इन लेबल्स से उत्पाद की पहचान करें: ${_labels.join(", ")}, सही निपटान विधियों को समझाएं। पर्यावरण सुरक्षा सुनिश्चित करने के लिए स्पष्ट, पालन करने में आसान कदम प्रदान करें और कार्य के रूप में कुछ शिल्प कार्य विचार भी दें। सरल भाषा का उपयोग करें ताकि एक 8 वर्षीय बच्चा भी इसे सही तरीके से निपटा सके। अनावश्यक वाक्यांशों से बचें; जानकारी सीधे दें और कार्यों को बुलेटिन में अलग से सूचीबद्ध करें और उत्पाद की श्रेणी बताएं।";
      }
    } else if (language == "Tamil") {
      if (query == "Product Details") {
        formattedQuery =
            "இந்த லேபிள்களின் அடிப்படையில்: ${_labels.join(", ")}, தயாரிப்பை அடையாளம் காணவும். அதன் தினசரி வாழ்க்கையில் முக்கியத்துவம் மற்றும் பயனர்களால் அனுபவிக்கப்படும் மூன்று முக்கிய நன்மைகள் மற்றும் தீமைகள் பற்றி விரிவாக விளக்கவும்.";
      } else if (query == "Environmental Impact") {
        formattedQuery =
            "இந்த லேபிள்களைப் பயன்படுத்தி: ${_labels.join(", ")}, தயாரிப்பை தீர்மானிக்கவும். அதன் சுற்றுச்சூழல் தாக்கத்தை பகுப்பாய்வு செய்யவும், அதில் பருவநிலை மாற்றம் மற்றும் நடைமுறை பயன்பாடுகள் அடங்கும். இது தீங்கு விளைவிப்பதாக இருந்தால், மாசுபாட்டை குறைக்கும் மற்றும் நிலைத்தன்மையை ஊக்குவிக்கும் நியாயமான வழிகளை பரிந்துரைக்கவும். தேவையற்ற அறிமுகங்களை தவிர்க்கவும் மற்றும் உள்ளடக்கத்தை மட்டும் வழங்கவும்.";
      } else if (query == "Health Impact") {
        formattedQuery =
            "இந்த லேபிள்களின் அடிப்படையில் தயாரிப்பை அடையாளம் காணவும்: ${_labels.join(", ")}. அதன் ஆரோக்கிய நன்மைகள் மற்றும் சாத்தியமான ஆபத்துகள் பற்றி விவாதிக்கவும். பாதுகாப்பு, ஒவ்வாமை அல்லது நீண்டகால விளைவுகள் குறித்து பொதுவாக உள்ள கவலைகளை குறிப்பிடவும். தேவையற்ற அறிமுகங்களை தவிர்த்து நேரடி, தெளிவான தகவலை வழங்கவும்.";
      } else {
        formattedQuery =
            "இந்த லேபிள்களைப் பயன்படுத்தி தயாரிப்பை அடையாளம் காணவும்: ${_labels.join(", ")}, சரியான அகற்றும் முறைகளை விளக்கவும். சுற்றுச்சூழல் பாதுகாப்பை உறுதி செய்ய தெளிவான, பின்பற்ற எளிதான படிகளை வழங்கவும் மற்றும் பணியாக சில கைவினை யோசனைகளையும் வழங்கவும். எளிய மொழியைப் பயன்படுத்தவும், 8 வயது குழந்தை கூட அதை சரியாக அகற்ற முடியும். தேவையற்ற அறிமுகங்களை தவிர்க்கவும்; தகவலை நேரடியாக வழங்கவும், பணிகளை தனியாக பட்டியலிடவும் மற்றும் தயாரிப்பின் வகையை குறிப்பிடவும்.";
      }
    } else {
      // English (default)
      if (query == "Product Details") {
        formattedQuery =
            "Based on these labels: ${_labels.join(", ")}, identify the product. Explain its significance in daily life and highlight three key advantages and disadvantages that users commonly experience and explain in detail";
      } else if (query == "Environmental Impact") {
        formattedQuery =
            "Using these labels: ${_labels.join(", ")}, determine the product. Analyze its impact on the environment, including its effects on ecosystems and practical uses. If it poses harm, suggest realistic ways to repurpose or dispose of it responsibly to minimize pollution and promote sustainability. Do not include phrases like 'Below is' or 'Here is' in your response; provide only the content and explain in detail";
      } else if (query == "Health Impact") {
        formattedQuery =
            "Identify the product based on these labels: ${_labels.join(", ")}. Discuss its health benefits and potential risks when used or consumed. Address common concerns people face regarding safety, allergies, or long-term effects. Avoid unnecessary introductory phrases and provide direct, clear information and explain in detail with needed measure to be taken";
      } else {
        formattedQuery =
            "Recognizing the product from these labels: ${_labels.join(", ")}, explain the correct disposal methods. Provide clear, easy-to-follow steps that ensure environmental safety and also provide some craft work ideas as Task .Use simple language so even an 8-year-old can understand how to dispose of it properly without harming nature. Do not include phrases like 'Below is' or 'Here is'; deliver the information directly and after explaining give me the task needed to be done to dispose them mention those task seperatedly as Task to be taken followed by the task only in bulletin and say what type of category does the product belongs to";
      }
    }

    setState(() {
      _isLoading = true;
      _responseText = "Fetching data...";
    });

    print("🔄 Fetching API Key...");
    String? apiKey = await _fetchAPIKey();

    if (apiKey == null) {
      print("❌ No valid API key found.");
      setState(() {
        _isLoading = false;
        _responseText = "This may take a while. Please try again later.";
      });
      return;
    }

    var url = Uri.parse("https://open-ai21.p.rapidapi.com/conversationllama");

    var headers = {
      "X-RapidAPI-Key": apiKey,
      "Content-Type": "application/json"
    };

    var body = jsonEncode({
      "messages": [
        {"role": "user", "content": formattedQuery}
      ],
      "web_access": false
    });

    print("🚀 Sending API Request...");
    print("📝 Request Body: $body");

    try {
      var response = await http.post(url, headers: headers, body: body);
      print("🔍 Response Status Code: ${response.statusCode}");
      print("📩 Raw Response Body: ${response.body}");

      // Ensure proper UTF-8 decoding.
      String decodedBody = utf8.decode(response.bodyBytes, allowMalformed: true);
      print("📩 Decoded Response Body: $decodedBody");

      setState(() {
        _responseText = formatResponseText(decodedBody);
        _isLoading = false;
      });
    } catch (e) {
      print("⚠️ Error Fetching Data: $e");
      setState(() {
        _responseText = "Error fetching response!";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: Colors.green[900],
            elevation: 10,
            pinned: true,
            expandedHeight: 280,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 16, bottom: 16),
              centerTitle: true,
              title: innerBoxIsScrolled
                  ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Product Analysis",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      letterSpacing: 1.2,
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: [Colors.greenAccent, Colors.white],
                        ).createShader(Rect.fromLTWH(0, 0, 200, 40)),
                      shadows: [
                        Shadow(
                          blurRadius: 6,
                          color: Colors.black87,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                ],
              )
                  : null,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(widget.image, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.5),
                          Colors.transparent,
                          Colors.green[900]!.withOpacity(0.7),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            Container(
              color: Colors.green[100],
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.green[900],
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.green[700],
                onTap: (index) {
                  List<String> queries = ["Product Details", "Environmental Impact", "Health Impact", "Disposal Measures"];
                  _fetchData(queries[index]);
                },
                tabs: [
                  Tab(icon: Icon(Icons.info_outline, color: Colors.green[800]), text: "Product Details"),
                  Tab(icon: Icon(Icons.eco, color: Colors.green[800]), text: "Environmental Impact"),
                  Tab(icon: Icon(Icons.health_and_safety, color: Colors.green[800]), text: "Health Impact"),
                  Tab(icon: Icon(Icons.delete_outline, color: Colors.green[800]), text: "Disposal Measures"),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 500),
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: Colors.green))
                    : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withOpacity(0.1), // Glassmorphic effect
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: Offset(2, 4),
                        )
                      ],
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.insights, color: Colors.green[900], size: 28),
                            SizedBox(width: 8),
                            Text(
                              "Analysis Result",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                foreground: Paint()
                                  ..shader = LinearGradient(
                                    colors: [Colors.green[800]!, Colors.teal[300]!],
                                  ).createShader(Rect.fromLTWH(0, 0, 200, 50)),
                              ),
                            ),
                          ],
                        ),
                        Divider(color: Colors.green[700], thickness: 1.5),
                        SizedBox(height: 10),

                        /// **Typing Animation for Response**
                        AnimatedOpacity(
                          duration: Duration(milliseconds: 800),
                          opacity: 1.0,
                          child: DefaultTextStyle(
                            style: TextStyle(
                              fontSize: 17,
                              color: Colors.black87,
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
                            child: AnimatedTextKit(
                              animatedTexts: [
                                TypewriterAnimatedText(
                                  _responseText,
                                  speed: Duration(milliseconds: 30), // Adjust speed here
                                ),
                              ],
                              isRepeatingAnimation: false,
                            ),
                          ),
                        ),

                        SizedBox(height: 12),
                        if (_tabController.index == 3)
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DisposalPage(responseText: _responseText,image:widget.image,count: _count,),
                                  ),
                                );
                              },
                              icon: Icon(Icons.battery_saver, color: Colors.white),
                              label: Text(
                                " Dispose & Clean!",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[800],
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                              ),
                            ),
                          ),
                        SizedBox(height: 12),
                        Divider(color: Colors.green[700], thickness: 1.5),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.eco, color: Colors.green[700], size: 24),
                            SizedBox(width: 4),
                            Text(
                              "Eco-Friendly Insights",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[800],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  String formatResponseText(String responseBody) {
    try {
      var decodedJson = jsonDecode(responseBody);
      if (decodedJson is Map<String, dynamic> && decodedJson.containsKey("result")) {
        String text = decodedJson["result"];
        // Define a replacement map for fixing encoding issues
        final Map<String, String> replacements = {
          "â": "–", // En dash
          "â": " ", // Space
          "â¢": "•", // Bullet point
          "â": "\"", "â": "\"", // Double quotes
          "â¦": "...", // Ellipsis
          "â": "'", // Apostrophe
          "â": "-", // Horizontal line
          "â": "_", // Underscore
          "â¢": "™", // Trademark symbol
          "â": "✔", // Checkmark
        };
        // Apply replacements
        replacements.forEach((key, value) {
          text = text.replaceAll(key, value);
        });
        // Improve readability with formatting
        text = text.replaceAll("\\n", "\n").trim();
        text = text.replaceAll(RegExp(r"(?<=\d)\.\s"), ".\n\n");
        return text;
      } else {
        return "Invalid response format!";
      }
    } catch (e) {
      return "⚠️ Error Decoding Data: $e";
    }
  }
}

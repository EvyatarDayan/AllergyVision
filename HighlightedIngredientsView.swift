//
//  HighlightedIngredientsView.swift
//  AllergyVision
//
//  Created by EVYATAR DAYAN on 2025-10-17.
//

import SwiftUI

struct HighlightedIngredientsView: View {
    let ingredients: String
    @StateObject private var userAllergensManager = UserAllergensManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Ingredients", systemImage: "list.bullet")
                .font(.headline)
            
            Text(attributedIngredients())
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    // Function to detect allergens from ingredients text
    func detectedAllergens() -> [String] {
        let keywords = userAllergensManager.allergenKeywordsLowercased()
        if keywords.isEmpty { return [] }
        
        var detectedAllergens: Set<String> = []
        let translations = getIngredientTranslations()
        let lowercasedIngredients = ingredients.lowercased()
        
        // Check for direct matches
        for keyword in keywords {
            if lowercasedIngredients.contains(keyword) {
                let normalizedAllergen = normalizeAllergenName(keyword)
                detectedAllergens.insert(normalizedAllergen)
            }
        }
        
        // Check for translation matches
        for (foreignWord, englishWord) in translations {
            if lowercasedIngredients.contains(foreignWord.lowercased()) {
                let lowercasedEnglish = englishWord.lowercased()
                for keyword in keywords {
                    if lowercasedEnglish.contains(keyword) {
                        let normalizedAllergen = normalizeAllergenName(keyword)
                        detectedAllergens.insert(normalizedAllergen)
                    }
                }
            }
        }
        
        return Array(detectedAllergens).sorted()
    }
    
    // Function to normalize allergen names to avoid duplicates like "egg" and "eggs"
    private func normalizeAllergenName(_ allergen: String) -> String {
        let lowercased = allergen.lowercased()
        
        // Define normalization rules to avoid duplicates
        let normalizationMap: [String: String] = [
            // Eggs
            "egg": "Egg",
            "eggs": "Egg",
            "egg yolk": "Egg",
            "egg white": "Egg",
            "egg whites": "Egg",
            "egg yolks": "Egg",
            
            // Milk
            "milk": "Milk",
            "milks": "Milk",
            "cow milk": "Milk",
            "goat milk": "Milk",
            "sheep milk": "Milk",
            "skimmed milk": "Milk",
            "whole milk": "Milk",
            "milk powder": "Milk",
            "milk protein": "Milk",
            "milk fat": "Milk",
            
            // Fish
            "fish": "Fish",
            "salmon": "Fish",
            "tuna": "Fish",
            "cod": "Fish",
            "haddock": "Fish",
            "anchovy": "Fish",
            "sardine": "Fish",
            "mackerel": "Fish",
            
            // Shellfish
            "shellfish": "Shellfish",
            "shrimp": "Shellfish",
            "crab": "Shellfish",
            "lobster": "Shellfish",
            "crayfish": "Shellfish",
            "prawn": "Shellfish",
            "prawns": "Shellfish",
            
            // Tree nuts
            "nuts": "Tree Nuts",
            "tree nuts": "Tree Nuts",
            "almond": "Tree Nuts",
            "almonds": "Tree Nuts",
            "hazelnut": "Tree Nuts",
            "hazelnuts": "Tree Nuts",
            "walnut": "Tree Nuts",
            "walnuts": "Tree Nuts",
            "cashew": "Tree Nuts",
            "cashews": "Tree Nuts",
            "pecan": "Tree Nuts",
            "pecans": "Tree Nuts",
            "pistachio": "Tree Nuts",
            "pistachios": "Tree Nuts",
            "brazil nut": "Tree Nuts",
            "brazil nuts": "Tree Nuts",
            "macadamia": "Tree Nuts",
            "macadamias": "Tree Nuts",
            
            // Peanuts
            "peanut": "Peanut",
            "peanuts": "Peanut",
            "groundnut": "Peanut",
            "groundnuts": "Peanut",
            
            // Wheat
            "wheat": "Wheat",
            "gluten": "Wheat",
            "wheat flour": "Wheat",
            "wheat protein": "Wheat",
            "wheat starch": "Wheat",
            
            // Soy
            "soy": "Soy",
            "soybean": "Soy",
            "soybeans": "Soy",
            "soy protein": "Soy",
            "soy flour": "Soy",
            "soy milk": "Soy",
            "soy sauce": "Soy",
            "soy lecithin": "Soy",
            
            // Sesame
            "sesame": "Sesame",
            "sesame seed": "Sesame",
            "sesame seeds": "Sesame",
            "sesame oil": "Sesame",
            
            // Mustard
            "mustard": "Mustard",
            "mustard seed": "Mustard",
            "mustard seeds": "Mustard",
            "mustard powder": "Mustard",
            
            // Celery
            "celery": "Celery",
            "celery seed": "Celery",
            "celery seeds": "Celery",
            "celery salt": "Celery",
            
            // Lupin
            "lupin": "Lupin",
            "lupine": "Lupin",
            "lupins": "Lupin",
            
            // Sulfites
            "sulfites": "Sulfites",
            "sulphites": "Sulfites",
            "sulfur dioxide": "Sulfites",
            "sulphur dioxide": "Sulfites",
            
            // Mollusks
            "mollusk": "Mollusk",
            "mollusks": "Mollusk",
            "mollusc": "Mollusk",
            "molluscs": "Mollusk",
            "clam": "Mollusk",
            "clams": "Mollusk",
            "mussel": "Mollusk",
            "mussels": "Mollusk",
            "oyster": "Mollusk",
            "oysters": "Mollusk",
            "squid": "Mollusk",
            "scallop": "Mollusk",
            "scallops": "Mollusk",
            "octopus": "Mollusk",
            
            // Other common allergens
            "corn": "Corn",
            "maize": "Corn",
            "buckwheat": "Buckwheat",
            "chickpea": "Chickpea",
            "chickpeas": "Chickpea",
            "lentil": "Lentil",
            "lentils": "Lentil",
            "pea": "Pea",
            "peas": "Pea",
            "bean": "Bean",
            "beans": "Bean",
            "kidney bean": "Bean",
            "kidney beans": "Bean",
            "navy bean": "Bean",
            "navy beans": "Bean",
            "pinto bean": "Bean",
            "pinto beans": "Bean",
            "black bean": "Bean",
            "black beans": "Bean",
            "oats": "Oats",
            "oat": "Oats",
            "garlic": "Garlic",
            "onion": "Onion",
            "onions": "Onion",
            "kiwi": "Kiwi",
            "banana": "Banana",
            "bananas": "Banana",
            "avocado": "Avocado",
            "avocados": "Avocado",
            "mango": "Mango",
            "mangos": "Mango",
            "mangoes": "Mango",
            "apple": "Apple",
            "apples": "Apple",
            "peach": "Peach",
            "peaches": "Peach",
            "tomato": "Tomato",
            "tomatoes": "Tomato",
            "citrus": "Citrus",
            "orange": "Citrus",
            "oranges": "Citrus",
            "lemon": "Citrus",
            "lemons": "Citrus",
            "lime": "Citrus",
            "limes": "Citrus",
            "grapefruit": "Citrus",
            "grapefruits": "Citrus",
            "strawberry": "Strawberry",
            "strawberries": "Strawberry",
            "chocolate": "Chocolate",
            "cocoa": "Chocolate",
            "yeast": "Yeast",
            "poppy seed": "Poppy Seed",
            "poppy seeds": "Poppy Seed",
            "sunflower seed": "Sunflower Seed",
            "sunflower seeds": "Sunflower Seed",
            "pumpkin seed": "Pumpkin Seed",
            "pumpkin seeds": "Pumpkin Seed"
        ]
        
        // Return normalized name if found, otherwise capitalize the original
        return normalizationMap[lowercased] ?? allergen.capitalized
    }
    
    private func attributedIngredients() -> AttributedString {
        var attributed = AttributedString(ingredients)
        let keywords = userAllergensManager.allergenKeywordsLowercased()
        if keywords.isEmpty { return attributed }

        let nsString = ingredients as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)
        let wordPattern = "[A-Za-zÀ-ÿ'-]+"
        if let regex = try? NSRegularExpression(pattern: wordPattern, options: []) {
            regex.enumerateMatches(in: ingredients, options: [], range: fullRange) { match, _, _ in
                guard let match = match else { return }
                let word = nsString.substring(with: match.range)
                let lower = word.lowercased()
                
                // Check if word matches any allergen keyword directly
                let isDirectMatch = keywords.contains(where: { lower.contains($0) })
                
                // Check if word is a translation of an allergen
                let isTranslationMatch = isAllergenTranslation(word: lower, keywords: keywords)
                
                if isDirectMatch || isTranslationMatch {
                    if let range = Range(match.range, in: ingredients) {
                        let token = String(ingredients[range])
                        if let attrRange = attributed.range(of: token) {
                            attributed[attrRange].foregroundColor = .red
                            attributed[attrRange].font = .body.weight(.semibold)
                        }
                    }
                }
            }
        }
        
        return attributed
    }
    
    private func isAllergenTranslation(word: String, keywords: Set<String>) -> Bool {
        // Get ingredient translations
        let translations = getIngredientTranslations()
        
        // Check if the word translates to any allergen keyword
        for (foreignWord, englishWord) in translations {
            if word.contains(foreignWord.lowercased()) {
                // Check if the English translation matches any allergen keyword
                if keywords.contains(where: { englishWord.lowercased().contains($0) }) {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func getIngredientTranslations() -> [String: String] {
        return [
            // MILK translations
            "maito": "milk", "kerma": "cream", "lait": "milk", "crème": "cream",
            "milch": "milk", "sahne": "cream", "leche": "milk", "crema": "cream",
            "mjölk": "milk", "mjolk": "milk", "melk": "milk", "latte": "milk",
            "leite": "milk", "mleko": "milk", "молоко": "milk", "牛乳": "milk", "牛奶": "milk",
            "heratuote": "whey", "lactosérum": "whey", "molke": "whey", "suero": "whey",
            
            // EGG translations
            "ägg": "egg", "äggula": "egg yolk", "äggvita": "egg white", "munas": "egg",
            "œuf": "egg", "jaune d'œuf": "egg yolk", "blanc d'œuf": "egg white",
            "ei": "egg", "eigelb": "egg yolk", "eiweiß": "egg white",
            "huevo": "egg", "yema": "egg yolk", "clara": "egg white",
            "ovo": "egg", "gema": "egg yolk", "clara de ovo": "egg white",
            
            // FISH translations
            "fisk": "fish", "lax": "salmon", "tonfisk": "tuna", "torsk": "cod",
            "kala": "fish", "lohen": "salmon", "tonnikala": "tuna", "turska": "cod",
            "poisson": "fish", "saumon": "salmon", "thon": "tuna", "morue": "cod",
            "fisch": "fish", "lachs": "salmon", "thunfisch": "tuna", "kabeljau": "cod",
            "pez": "fish", "salmón": "salmon", "atún": "tuna", "bacalao": "cod",
            "peixe": "fish", "salmão": "salmon", "atum": "tuna", "bacalhau": "cod",
            
            // SHELLFISH translations
            "skaldjur": "shellfish", "räkor": "shrimp", "krabba": "crab", "hummer": "lobster",
            "äyriäiset": "shellfish", "katkaravut": "shrimp", "rapu": "crab", "hummeri": "lobster",
            "crustacés": "shellfish", "crevettes": "shrimp", "crabe": "crab", "homard": "lobster",
            "krebstiere": "shellfish", "garnelen": "shrimp", "krabbe": "crab", "hummer de": "lobster",
            "mariscos": "shellfish", "camarones": "shrimp", "cangrejo": "crab", "langosta": "lobster",
            "frutos do mar": "shellfish", "camarão": "shrimp", "caranguejo": "crab", "lagosta": "lobster",
            
            // TREE NUTS translations
            "nötter": "nuts", "mandel": "almond", "hasselnöt": "hazelnut", "valnöt": "walnut",
            "pähkinät": "nuts", "manteli": "almond", "pähkinä": "hazelnut", "saksanpähkinä": "walnut",
            "noix": "nuts", "amande": "almond", "noisette": "hazelnut", "noix de grenoble": "walnut",
            "nüsse": "nuts", "mandel de": "almond", "haselnuss": "hazelnut", "walnuss": "walnut",
            "nueces": "nuts", "almendra": "almond", "avellana": "hazelnut", "nuez": "walnut",
            "nozes": "nuts", "amêndoa": "almond", "avelã": "hazelnut", "noz": "walnut",
            "cashew": "cashew", "pecan": "pecan", "pistachio": "pistachio", "brazil": "brazil nut",
            "macadamia": "macadamia", "paranöt": "brazil nut",
            
            // PEANUT translations
            "jordnötter": "peanut", "jordnöt": "peanut", "maapähkinä": "peanut",
            "cacahuète": "peanut", "arachide": "peanut", "erdnuss": "peanut",
            "cacahuete": "peanut", "maní": "peanut", "amendoim": "peanut",
            
            // WHEAT translations
            "vete": "wheat", "vetemjöl": "wheat flour", "gluten": "gluten",
            "vehnä": "wheat", "vehnäjauho": "wheat flour", "gluteeni": "gluten",
            "blé": "wheat", "farine de blé": "wheat flour", "gluten français": "gluten",
            "weizen": "wheat", "weizenmehl": "wheat flour", "gluten allemand": "gluten",
            "trigo": "wheat", "harina de trigo": "wheat flour", "gluten espagnol": "gluten",
            "trigo português": "wheat", "farinha de trigo": "wheat flour", "glúten": "gluten",
            
            // SOY translations
            "soja": "soy", "sojabönor": "soybeans", "sojamjölk": "soy milk",
            "soija": "soy", "soijapavut": "soybeans", "soijamaito": "soy milk",
            "soja français": "soy", "haricots de soja": "soybeans", "lait de soja": "soy milk",
            "soja allemand": "soy", "sojabohnen": "soybeans", "sojamilch": "soy milk",
            "soja espagnol": "soy", "frijoles de soja": "soybeans", "leche de soja": "soy milk",
            "soja portugais": "soy", "feijão de soja": "soybeans", "leite de soja": "soy milk",
            
            // SESAME translations
            "sesam": "sesame", "sesamfrön": "sesame seeds", "sesamolja": "sesame oil",
            "seesami": "sesame", "seesaminsiemenet": "sesame seeds", "seesamiöljy": "sesame oil",
            "sésame": "sesame", "graines de sésame": "sesame seeds", "huile de sésame": "sesame oil",
            "sesam allemand": "sesame", "sesamsamen": "sesame seeds", "sesamöl": "sesame oil",
            "sésamo": "sesame", "semillas de sésamo": "sesame seeds", "aceite de sésamo": "sesame oil",
            "gergelim": "sesame", "sementes de gergelim": "sesame seeds", "óleo de gergelim": "sesame oil",
            
            // MUSTARD translations
            "senap": "mustard", "senapsfrö": "mustard seed", "senapspulver": "mustard powder",
            "sinappi": "mustard", "sinapinsiemenet": "mustard seed", "sinappijauhe": "mustard powder",
            "moutarde": "mustard", "graines de moutarde": "mustard seed", "poudre de moutarde": "mustard powder",
            "senf": "mustard", "senfsamen": "mustard seed", "senfpulver": "mustard powder",
            "mostaza": "mustard", "semillas de mostaza": "mustard seed", "polvo de mostaza": "mustard powder",
            "mostarda": "mustard", "sementes de mostarda": "mustard seed", "pó de mostarda": "mustard powder",
            
            // CELERY translations
            "selleri": "celery", "selleriblad": "celery leaves", "sellerifrö": "celery seed",
            "selleri finlandais": "celery", "sellerinlehdet": "celery leaves", "sellerinsiemenet": "celery seed",
            "céleri": "celery", "feuilles de céleri": "celery leaves", "graines de céleri": "celery seed",
            "sellerie": "celery", "sellerieblätter": "celery leaves", "selleriesamen": "celery seed",
            "apio": "celery", "hojas de apio": "celery leaves", "semillas de apio": "celery seed",
            "aipo": "celery", "folhas de aipo": "celery leaves", "sementes de aipo": "celery seed",
            
            // TOMATO translations (your specific case)
            "tomat": "tomato", "tomater": "tomatoes", "krossade tomater": "crushed tomatoes",
            "tomatjuice": "tomato juice", "tomatpuré": "tomato puree", "tomatkonserv": "canned tomatoes",
            "tomaatti": "tomato", "tomaatit": "tomatoes", "murskattu tomaatti": "crushed tomatoes",
            "tomaattimehu": "tomato juice", "tomaattisose": "tomato puree", "tomaattikonservi": "canned tomatoes",
            "tomate": "tomato", "tomates": "tomatoes", "tomates écrasées": "crushed tomatoes",
            "jus de tomate": "tomato juice", "purée de tomate": "tomato puree", "tomates en conserve": "canned tomatoes",
            "tomate allemand": "tomato", "tomaten": "tomatoes", "zerdrückte tomaten": "crushed tomatoes",
            "tomatensaft": "tomato juice", "tomatensauce": "tomato puree", "dosen tomaten": "canned tomatoes",
            "tomate espagnol": "tomato", "tomates espagnoles": "tomatoes", "tomates trituradas": "crushed tomatoes",
            "jugo de tomate": "tomato juice", "puré de tomate": "tomato puree", "tomates enlatados": "canned tomatoes",
            "tomate portugais": "tomato", "tomates portugaises": "tomatoes", "tomates esmagados": "crushed tomatoes",
            "suco de tomate": "tomato juice", "purê de tomate": "tomato puree", "tomates enlatados portugais": "canned tomatoes",
            "pomodoro": "tomato", "pomodori": "tomatoes", "pomodori schiacciati": "crushed tomatoes",
            "succo di pomodoro": "tomato juice", "passata di pomodoro": "tomato puree", "pomodori in scatola": "canned tomatoes",
            
            // CITRUS translations
            "citrus": "citrus", "apelsin": "orange", "citron": "lemon", "lime": "lime", "grapefrukt": "grapefruit",
            "sitrus": "citrus", "appelsiini": "orange", "sitruuna": "lemon", "lime finlandais": "lime", "greippi": "grapefruit",
            "agrumes": "citrus", "orange": "orange", "citron français": "lemon", "citron vert": "lime", "pamplemousse": "grapefruit",
            "zitrus": "citrus", "orange allemand": "orange", "zitrone": "lemon", "limette": "lime", "grapefruit": "grapefruit",
            "cítricos": "citrus", "naranja": "orange", "limón": "lemon", "lima": "lime", "pomelo": "grapefruit",
            "citrinos": "citrus", "laranja": "orange", "limão": "lemon", "lima portugais": "lime", "toranja": "grapefruit",
            
            // STRAWBERRY translations
            "jordgubbe": "strawberry", "jordgubbar": "strawberries", "jordgubbsmak": "strawberry flavor",
            "mansikka": "strawberry", "mansikat": "strawberries", "mansikanmaku": "strawberry flavor",
            "fraise": "strawberry", "fraises": "strawberries", "goût de fraise": "strawberry flavor",
            "erdbeere": "strawberry", "erdbeeren": "strawberries", "erdbeergeschmack": "strawberry flavor",
            "fresa": "strawberry", "fresas": "strawberries", "sabor a fresa": "strawberry flavor",
            "morango": "strawberry", "morangos": "strawberries", "sabor de morango": "strawberry flavor",
            
            // CHOCOLATE translations
            "choklad": "chocolate", "kakao": "cocoa", "chokladpulver": "chocolate powder",
            "suklaa": "chocolate", "kaakao": "cocoa", "suklaajauhe": "chocolate powder",
            "chocolat": "chocolate", "cacao": "cocoa", "poudre de chocolat": "chocolate powder",
            "schokolade": "chocolate", "kakao allemand": "cocoa", "schokoladenpulver": "chocolate powder",
            "chocolate": "chocolate", "cacao espagnol": "cocoa", "polvo de chocolate": "chocolate powder",
            "chocolate portugais": "chocolate", "cacau": "cocoa", "pó de chocolate": "chocolate powder",
            
            // YEAST translations
            "jäst": "yeast", "jästextrakt": "yeast extract", "bäckerjäst": "baker's yeast",
            "hiiva": "yeast", "hiivauute": "yeast extract", "leipomohiiva": "baker's yeast",
            "levure": "yeast", "extrait de levure": "yeast extract", "levure de boulanger": "baker's yeast",
            "hefe": "yeast", "hefeextrakt": "yeast extract", "bäckerhefe": "baker's yeast",
            "levadura": "yeast", "extracto de levadura": "yeast extract", "levadura de panadero": "baker's yeast",
            "fermento": "yeast", "extrato de fermento": "yeast extract", "fermento de padeiro": "baker's yeast",
            
            // General ingredient translations
            "rapsolja": "rapeseed oil", "vatten": "water", "chili": "chili", "socker": "sugar",
            "salt": "salt", "vitlök": "garlic", "ättiksprit": "vinegar spirit", "spiskummin": "cumin",
            "vinäger": "vinegar", "paprikapulver": "paprika powder", "arom": "flavoring",
            "konserveringsmedel": "preservatives", "förtjockningsmedel": "thickening agent",
            "surhetsreglerande medel": "acidity regulator", "happo": "acid", "sitruunahappo": "citric acid",
            "hapate": "starter culture", "stabilointiaineet": "stabilizers",
            "johanneksenleipäpuujauhe": "carob bean gum", "karrageeni": "carrageenan",
            "acide": "acid", "acide citrique": "citric acid", "ferments": "starter culture",
            "stabilisants": "stabilizers", "farine de caroube": "carob bean gum", "carraghénane": "carrageenan",
            "säure": "acid", "zitronensäure": "citric acid", "fermente": "starter culture",
            "stabilisatoren": "stabilizers", "johannisbrotkernmehl": "carob bean gum", "carrageen": "carrageenan",
            "ácido": "acid", "ácido cítrico": "citric acid", "fermentos": "starter culture",
            "estabilizantes": "stabilizers", "harina de algarroba": "carob bean gum", "carragenano": "carrageenan"
        ]
    }
}

#Preview {
    HighlightedIngredientsView(ingredients: "Sugar, Palm Oil, Hazelnuts, Cocoa, Milk, Lecithin, Vanillin")
        .padding()
}

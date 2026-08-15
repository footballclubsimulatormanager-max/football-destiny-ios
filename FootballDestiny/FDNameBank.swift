import Foundation

/// Generates a player name coherent with a chosen nationality — the player never types
/// their own name, the game picks one from a first/last name pool tied to that country.
enum FDNameBank {
    private static let pools: [String: (first: [String], last: [String])] = [
        "France": (["Lucas", "Enzo", "Nathan", "Hugo", "Rayan", "Louis", "Adam", "Mathis"],
                    ["Martin", "Bernard", "Dubois", "Robert", "Moreau", "Laurent", "Fontaine", "Girard"]),
        "Angleterre": (["Jack", "Harry", "George", "Oliver", "Charlie", "James", "Thomas", "William"],
                       ["Smith", "Jones", "Taylor", "Brown", "Wilson", "Evans", "Walker", "Hughes"]),
        "Espagne": (["Alejandro", "Pablo", "Daniel", "Adrián", "Álvaro", "Diego", "Mario", "Iker"],
                    ["García", "Fernández", "López", "Martínez", "Sánchez", "Pérez", "Gómez", "Díaz"]),
        "Allemagne": (["Lukas", "Finn", "Leon", "Paul", "Jonas", "Maximilian", "Felix", "Elias"],
                      ["Müller", "Schmidt", "Schneider", "Fischer", "Weber", "Wagner", "Becker", "Hoffmann"]),
        "Italie": (["Alessandro", "Lorenzo", "Matteo", "Francesco", "Andrea", "Marco", "Davide", "Luca"],
                   ["Rossi", "Russo", "Ferrari", "Esposito", "Bianchi", "Romano", "Colombo", "Ricci"]),
        "Portugal": (["João", "Rui", "Diogo", "Miguel", "Bruno", "Tiago", "André", "Gonçalo"],
                     ["Silva", "Santos", "Ferreira", "Pereira", "Oliveira", "Costa", "Rodrigues", "Martins"]),
        "Pays-Bas": (["Daan", "Sem", "Lucas", "Milan", "Levi", "Finn", "Noah", "Bram"],
                     ["De Jong", "Jansen", "De Vries", "Bakker", "Visser", "Smit", "Meijer", "Mulder"]),
        "Belgique": (["Noah", "Liam", "Louis", "Lucas", "Arthur", "Victor", "Mathis", "Nathan"],
                     ["Peeters", "Janssens", "Maes", "Jacobs", "Mertens", "Willems", "Claes", "Goossens"]),
        "Brésil": (["Gabriel", "João", "Pedro", "Lucas", "Matheus", "Rafael", "Bruno", "Vitor"],
                   ["Silva", "Santos", "Oliveira", "Souza", "Costa", "Pereira", "Almeida", "Carvalho"]),
        "Argentine": (["Mateo", "Santiago", "Tomás", "Nicolás", "Juan", "Franco", "Facundo", "Bruno"],
                      ["González", "Rodríguez", "Fernández", "López", "Díaz", "Martínez", "Romero", "Sosa"]),
        "Uruguay": (["Agustín", "Bruno", "Diego", "Santiago", "Nicolás", "Federico", "Rodrigo", "Facundo"],
                    ["Rodríguez", "Pérez", "García", "González", "Fernández", "Silva", "Suárez", "Núñez"]),
        "Colombie": (["Juan", "Santiago", "Andrés", "Camilo", "Sebastián", "Miguel", "Cristian", "Julián"],
                     ["Rodríguez", "Gómez", "Martínez", "García", "Ramírez", "Torres", "Vargas", "Castro"]),
        "États-Unis": (["Ethan", "Michael", "Jacob", "Ryan", "Tyler", "Justin", "Kevin", "Brandon"],
                       ["Johnson", "Williams", "Miller", "Davis", "Anderson", "Thompson", "Moore", "Jackson"]),
        "Canada": (["Liam", "Jacob", "Ethan", "Nathan", "Owen", "Carter", "Logan", "Mason"],
                   ["Tremblay", "Roy", "Gagnon", "Bouchard", "Leblanc", "Gauthier", "Morin", "Fortin"]),
        "Mexique": (["José", "Luis", "Carlos", "Miguel", "Alejandro", "Diego", "Fernando", "Emiliano"],
                    ["Hernández", "García", "Martínez", "López", "González", "Pérez", "Sánchez", "Ramírez"]),
        "Sénégal": (["Ousmane", "Mamadou", "Ibrahima", "Cheikh", "Moussa", "Modou", "Amadou", "Abdoulaye"],
                    ["Diop", "Ndiaye", "Fall", "Sarr", "Diallo", "Ba", "Gueye", "Sy"]),
        "Côte d'Ivoire": (["Kouassi", "Yao", "Koffi", "Ibrahim", "Franck", "Serge", "Didier", "Junior"],
                          ["Kouamé", "Koné", "Bamba", "Traoré", "Diabaté", "Aka", "Ouattara", "Coulibaly"]),
        "Cameroun": (["Samuel", "Joseph", "André", "Patrick", "Jean", "Eric", "Vincent", "Christian"],
                     ["Mbarga", "Etoo", "Nkoulou", "Njie", "Fotso", "Onana", "Manga", "Ekambi"]),
        "Nigeria": (["Chinedu", "Emeka", "Ifeanyi", "Victor", "Samuel", "Kelechi", "Ahmed", "Musa"],
                    ["Okafor", "Adeyemi", "Balogun", "Eze", "Chukwu", "Okonkwo", "Abubakar", "Nwosu"]),
        "Maroc": (["Youssef", "Mehdi", "Amine", "Karim", "Hamza", "Yassine", "Reda", "Ayoub"],
                  ["El Amrani", "Benali", "Bennani", "Idrissi", "Alaoui", "Chraibi", "Fassi", "Tazi"]),
        "Algérie": (["Yacine", "Riyad", "Islam", "Mohamed", "Sofiane", "Karim", "Nabil", "Adel"],
                    ["Benali", "Boudiaf", "Cherif", "Hamdi", "Kaci", "Meziane", "Saidi", "Zerrouki"]),
        "Tunisie": (["Youssef", "Karim", "Mohamed", "Sami", "Wassim", "Aymen", "Anis", "Bilel"],
                    ["Trabelsi", "Jlassi", "Gharbi", "Chaabane", "Mansour", "Sassi", "Khalfallah", "Bouzid"]),
        "Égypte": (["Mohamed", "Ahmed", "Mahmoud", "Karim", "Amr", "Omar", "Youssef", "Hassan"],
                   ["El-Sayed", "Ibrahim", "Mostafa", "Farouk", "Hussein", "Mansour", "Salah", "Fathy"]),
        "Japon": (["Haruto", "Yuto", "Sota", "Ren", "Riku", "Kaito", "Sora", "Kenta"],
                  ["Sato", "Suzuki", "Takahashi", "Tanaka", "Watanabe", "Ito", "Yamamoto", "Nakamura"]),
        "Corée du Sud": (["Min-jun", "Seo-jun", "Do-yun", "Ji-ho", "Joon-ho", "Hyun-woo", "Tae-yang", "Jin-woo"],
                         ["Kim", "Lee", "Park", "Choi", "Jung", "Kang", "Yoon", "Lim"]),
        "Australie": (["Jack", "Oliver", "William", "Noah", "Ethan", "Lucas", "Cooper", "Harrison"],
                      ["Smith", "Jones", "Williams", "Brown", "Wilson", "Taylor", "Anderson", "Clarke"]),
        "Émirats Arabes Unis": (["Ahmed", "Mohammed", "Khalid", "Omar", "Rashid", "Saeed", "Hamdan", "Fahad"],
                                ["Al Nuaimi", "Al Falasi", "Al Suwaidi", "Al Marri", "Al Shamsi", "Al Zaabi", "Al Mazrouei", "Al Ketbi"]),
        "Arabie Saoudite": (["Abdullah", "Faisal", "Sultan", "Khalid", "Nasser", "Fahad", "Turki", "Bandar"],
                            ["Al-Qahtani", "Al-Otaibi", "Al-Ghamdi", "Al-Harbi", "Al-Dosari", "Al-Shehri", "Al-Zahrani", "Al-Malki"]),
        "Turquie": (["Emre", "Mehmet", "Mustafa", "Ahmet", "Kaan", "Berat", "Yusuf", "Burak"],
                    ["Yılmaz", "Kaya", "Demir", "Şahin", "Çelik", "Yıldız", "Aydın", "Öztürk"]),
        "Croatie": (["Luka", "Ivan", "Marko", "Ante", "Josip", "Filip", "Petar", "Nikola"],
                    ["Horvat", "Kovačević", "Babić", "Marić", "Jurić", "Novak", "Vuković", "Perić"]),
        "Suède": (["William", "Oscar", "Elias", "Hugo", "Lucas", "Alexander", "Viktor", "Erik"],
                  ["Andersson", "Johansson", "Karlsson", "Nilsson", "Eriksson", "Larsson", "Olsson", "Persson"]),
        "Norvège": (["Jakob", "Emil", "Noah", "Oskar", "Aksel", "Filip", "Isak", "Magnus"],
                    ["Hansen", "Johansen", "Olsen", "Larsen", "Andersen", "Pedersen", "Nilsen", "Kristiansen"]),
        "Danemark": (["William", "Oscar", "Carl", "Victor", "Malthe", "Alfred", "Oliver", "Magnus"],
                     ["Nielsen", "Jensen", "Hansen", "Pedersen", "Andersen", "Christensen", "Larsen", "Sørensen"]),
    ]

    private static let fallback: (first: [String], last: [String]) = (
        ["Alex", "Sam", "Robin", "Kim", "Charlie", "Noa"],
        ["Martin", "Bernard", "Silva", "Hansen", "García", "Kim"]
    )

    static func random(for nationality: String) -> (first: String, last: String) {
        let pool = pools[nationality] ?? fallback
        let first = pool.first.randomElement() ?? "Alex"
        let last = pool.last.randomElement() ?? "Martin"
        return (first, last)
    }

    /// Birth city, drawn from the real cities the club database already knows for that
    /// country — no second list to keep in sync, and the result is always plausible.
    static func randomCity(for nationality: String) -> String {
        let cities = Set(FDAllClubs.filter { $0.country == nationality }.map(\.city))
        if let pick = cities.randomElement() { return pick }
        return FDAllClubs.randomElement()?.city ?? "Inconnue"
    }

    /// The full generated identity for a nationality — the player never types any of it.
    static func identity(for nationality: String) -> (first: String, last: String, city: String) {
        let name = random(for: nationality)
        return (name.first, name.last, randomCity(for: nationality))
    }
}

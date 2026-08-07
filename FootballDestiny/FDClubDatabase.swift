import Foundation

// MARK: - Real clubs, real cities/countries — no crests, kits or official competition
// branding are used anywhere in the app (text only), to keep things low-risk for an
// unlicensed indie game. Gameplay stats (reputation/academy/youth minutes) are derived
// procedurally from division + country footballing tier, not sourced from any real data
// provider — so this file only needs a name/city/country/continent/division per club,
// making it easy to correct or extend later without touching the game engine.
//
// Coverage is intentionally broad rather than exhaustive: top flights across roughly
// 30 countries on all six confederations, plus a handful of well-known second
// divisions. Real-world promotion/relegation and league changes mean this list will
// drift out of date over time — treat it as a solid, easily-editable starting point.

struct FDClubSeed {
    let name: String
    let city: String
    let country: String
    let continent: String
    let division: Int
}

// Footballing "power tier" per country: 1 = elite, 2 = strong, 3 = developing.
// Used only to shape gameplay stats (reputation/academy/minutes), never shown as-is.
let FDCountryTier: [String: Int] = [
    "Angleterre": 1, "Espagne": 1, "Allemagne": 1, "Italie": 1, "France": 1, "Brésil": 1, "Argentine": 1,
    "Portugal": 2, "Pays-Bas": 2, "Belgique": 2, "Turquie": 2, "Mexique": 2, "États-Unis": 2, "Écosse": 2,
    "Uruguay": 2, "Colombie": 2, "Croatie": 2, "Autriche": 2, "Suisse": 2, "Danemark": 2, "Japon": 2, "Arabie Saoudite": 2,
    "Maroc": 3, "Égypte": 3, "Sénégal": 3, "Nigeria": 3, "Tunisie": 3, "Algérie": 3, "Afrique du Sud": 3,
    "Corée du Sud": 3, "Chine": 3, "Australie": 3, "Canada": 3, "Qatar": 3, "Émirats Arabes Unis": 3,
]

// MARK: - Seeds by confederation

private let FDEuropeSeeds: [FDClubSeed] = [
    // Angleterre — Premier League
    .init(name:"Arsenal", city:"Londres", country:"Angleterre", continent:"Europe", division:1),
    .init(name:"Manchester City", city:"Manchester", country:"Angleterre", continent:"Europe", division:1),
    .init(name:"Manchester United", city:"Manchester", country:"Angleterre", continent:"Europe", division:1),
    .init(name:"Liverpool", city:"Liverpool", country:"Angleterre", continent:"Europe", division:1),
    .init(name:"Chelsea", city:"Londres", country:"Angleterre", continent:"Europe", division:1),
    .init(name:"Tottenham Hotspur", city:"Londres", country:"Angleterre", continent:"Europe", division:1),
    .init(name:"Newcastle United", city:"Newcastle", country:"Angleterre", continent:"Europe", division:1),
    .init(name:"Aston Villa", city:"Birmingham", country:"Angleterre", continent:"Europe", division:1),
    .init(name:"West Ham United", city:"Londres", country:"Angleterre", continent:"Europe", division:1),
    .init(name:"Brighton & Hove Albion", city:"Brighton", country:"Angleterre", continent:"Europe", division:1),
    .init(name:"Everton", city:"Liverpool", country:"Angleterre", continent:"Europe", division:1),
    .init(name:"Fulham", city:"Londres", country:"Angleterre", continent:"Europe", division:1),
    .init(name:"Brentford", city:"Londres", country:"Angleterre", continent:"Europe", division:1),
    .init(name:"Crystal Palace", city:"Londres", country:"Angleterre", continent:"Europe", division:1),
    .init(name:"Wolverhampton Wanderers", city:"Wolverhampton", country:"Angleterre", continent:"Europe", division:1),
    .init(name:"Nottingham Forest", city:"Nottingham", country:"Angleterre", continent:"Europe", division:1),
    .init(name:"Bournemouth", city:"Bournemouth", country:"Angleterre", continent:"Europe", division:1),
    .init(name:"Leicester City", city:"Leicester", country:"Angleterre", continent:"Europe", division:1),
    .init(name:"Ipswich Town", city:"Ipswich", country:"Angleterre", continent:"Europe", division:1),
    .init(name:"Southampton", city:"Southampton", country:"Angleterre", continent:"Europe", division:1),
    // Angleterre — Championship (D2)
    .init(name:"Leeds United", city:"Leeds", country:"Angleterre", continent:"Europe", division:2),
    .init(name:"Burnley", city:"Burnley", country:"Angleterre", continent:"Europe", division:2),
    .init(name:"Sheffield United", city:"Sheffield", country:"Angleterre", continent:"Europe", division:2),
    .init(name:"West Bromwich Albion", city:"West Bromwich", country:"Angleterre", continent:"Europe", division:2),
    .init(name:"Norwich City", city:"Norwich", country:"Angleterre", continent:"Europe", division:2),
    .init(name:"Middlesbrough", city:"Middlesbrough", country:"Angleterre", continent:"Europe", division:2),
    .init(name:"Coventry City", city:"Coventry", country:"Angleterre", continent:"Europe", division:2),
    .init(name:"Watford", city:"Watford", country:"Angleterre", continent:"Europe", division:2),
    .init(name:"Hull City", city:"Hull", country:"Angleterre", continent:"Europe", division:2),
    .init(name:"Preston North End", city:"Preston", country:"Angleterre", continent:"Europe", division:2),
    .init(name:"Bristol City", city:"Bristol", country:"Angleterre", continent:"Europe", division:2),
    .init(name:"Swansea City", city:"Swansea", country:"Angleterre", continent:"Europe", division:2),
    .init(name:"Millwall", city:"Londres", country:"Angleterre", continent:"Europe", division:2),
    .init(name:"Stoke City", city:"Stoke-on-Trent", country:"Angleterre", continent:"Europe", division:2),
    .init(name:"Queens Park Rangers", city:"Londres", country:"Angleterre", continent:"Europe", division:2),
    // Écosse
    .init(name:"Celtic", city:"Glasgow", country:"Écosse", continent:"Europe", division:1),
    .init(name:"Rangers", city:"Glasgow", country:"Écosse", continent:"Europe", division:1),
    .init(name:"Aberdeen", city:"Aberdeen", country:"Écosse", continent:"Europe", division:1),
    .init(name:"Heart of Midlothian", city:"Édimbourg", country:"Écosse", continent:"Europe", division:1),
    .init(name:"Hibernian", city:"Édimbourg", country:"Écosse", continent:"Europe", division:1),
    .init(name:"Dundee United", city:"Dundee", country:"Écosse", continent:"Europe", division:1),

    // Espagne — La Liga
    .init(name:"Real Madrid", city:"Madrid", country:"Espagne", continent:"Europe", division:1),
    .init(name:"FC Barcelone", city:"Barcelone", country:"Espagne", continent:"Europe", division:1),
    .init(name:"Atlético Madrid", city:"Madrid", country:"Espagne", continent:"Europe", division:1),
    .init(name:"Athletic Bilbao", city:"Bilbao", country:"Espagne", continent:"Europe", division:1),
    .init(name:"Real Sociedad", city:"Saint-Sébastien", country:"Espagne", continent:"Europe", division:1),
    .init(name:"Real Betis", city:"Séville", country:"Espagne", continent:"Europe", division:1),
    .init(name:"Séville FC", city:"Séville", country:"Espagne", continent:"Europe", division:1),
    .init(name:"Villarreal", city:"Villarreal", country:"Espagne", continent:"Europe", division:1),
    .init(name:"Valence", city:"Valence", country:"Espagne", continent:"Europe", division:1),
    .init(name:"Celta Vigo", city:"Vigo", country:"Espagne", continent:"Europe", division:1),
    .init(name:"Getafe", city:"Getafe", country:"Espagne", continent:"Europe", division:1),
    .init(name:"Osasuna", city:"Pampelune", country:"Espagne", continent:"Europe", division:1),
    .init(name:"Rayo Vallecano", city:"Madrid", country:"Espagne", continent:"Europe", division:1),
    .init(name:"Girona", city:"Gérone", country:"Espagne", continent:"Europe", division:1),
    .init(name:"Alavés", city:"Vitoria-Gasteiz", country:"Espagne", continent:"Europe", division:1),
    .init(name:"Mallorca", city:"Palma", country:"Espagne", continent:"Europe", division:1),
    .init(name:"Las Palmas", city:"Las Palmas", country:"Espagne", continent:"Europe", division:1),
    .init(name:"Espanyol", city:"Barcelone", country:"Espagne", continent:"Europe", division:1),
    .init(name:"Leganés", city:"Leganés", country:"Espagne", continent:"Europe", division:1),
    .init(name:"Valladolid", city:"Valladolid", country:"Espagne", continent:"Europe", division:1),
    // Espagne — Segunda (D2)
    .init(name:"Deportivo La Corogne", city:"La Corogne", country:"Espagne", continent:"Europe", division:2),
    .init(name:"Sporting Gijón", city:"Gijón", country:"Espagne", continent:"Europe", division:2),
    .init(name:"Racing Santander", city:"Santander", country:"Espagne", continent:"Europe", division:2),
    .init(name:"Zaragoza", city:"Saragosse", country:"Espagne", continent:"Europe", division:2),
    .init(name:"Elche", city:"Elche", country:"Espagne", continent:"Europe", division:2),
    .init(name:"Cádiz", city:"Cadix", country:"Espagne", continent:"Europe", division:2),
    .init(name:"Almería", city:"Almería", country:"Espagne", continent:"Europe", division:2),
    .init(name:"Málaga", city:"Málaga", country:"Espagne", continent:"Europe", division:2),

    // Allemagne — Bundesliga
    .init(name:"Bayern Munich", city:"Munich", country:"Allemagne", continent:"Europe", division:1),
    .init(name:"Borussia Dortmund", city:"Dortmund", country:"Allemagne", continent:"Europe", division:1),
    .init(name:"RB Leipzig", city:"Leipzig", country:"Allemagne", continent:"Europe", division:1),
    .init(name:"Bayer Leverkusen", city:"Leverkusen", country:"Allemagne", continent:"Europe", division:1),
    .init(name:"Eintracht Francfort", city:"Francfort", country:"Allemagne", continent:"Europe", division:1),
    .init(name:"VfB Stuttgart", city:"Stuttgart", country:"Allemagne", continent:"Europe", division:1),
    .init(name:"Borussia Mönchengladbach", city:"Mönchengladbach", country:"Allemagne", continent:"Europe", division:1),
    .init(name:"SC Fribourg", city:"Fribourg-en-Brisgau", country:"Allemagne", continent:"Europe", division:1),
    .init(name:"1. FC Union Berlin", city:"Berlin", country:"Allemagne", continent:"Europe", division:1),
    .init(name:"Wolfsburg", city:"Wolfsburg", country:"Allemagne", continent:"Europe", division:1),
    .init(name:"Mayence 05", city:"Mayence", country:"Allemagne", continent:"Europe", division:1),
    .init(name:"TSG Hoffenheim", city:"Sinsheim", country:"Allemagne", continent:"Europe", division:1),
    .init(name:"Werder Brême", city:"Brême", country:"Allemagne", continent:"Europe", division:1),
    .init(name:"FC Augsbourg", city:"Augsbourg", country:"Allemagne", continent:"Europe", division:1),
    .init(name:"VfL Bochum", city:"Bochum", country:"Allemagne", continent:"Europe", division:1),
    .init(name:"1. FC Heidenheim", city:"Heidenheim", country:"Allemagne", continent:"Europe", division:1),
    .init(name:"FC Saint-Pauli", city:"Hambourg", country:"Allemagne", continent:"Europe", division:1),
    .init(name:"Holstein Kiel", city:"Kiel", country:"Allemagne", continent:"Europe", division:1),
    // Allemagne — 2. Bundesliga (D2)
    .init(name:"Hambourg SV", city:"Hambourg", country:"Allemagne", continent:"Europe", division:2),
    .init(name:"1. FC Cologne", city:"Cologne", country:"Allemagne", continent:"Europe", division:2),
    .init(name:"Hertha Berlin", city:"Berlin", country:"Allemagne", continent:"Europe", division:2),
    .init(name:"Schalke 04", city:"Gelsenkirchen", country:"Allemagne", continent:"Europe", division:2),
    .init(name:"Fortuna Düsseldorf", city:"Düsseldorf", country:"Allemagne", continent:"Europe", division:2),
    .init(name:"Karlsruher SC", city:"Karlsruhe", country:"Allemagne", continent:"Europe", division:2),
    .init(name:"Greuther Fürth", city:"Fürth", country:"Allemagne", continent:"Europe", division:2),
    .init(name:"Hansa Rostock", city:"Rostock", country:"Allemagne", continent:"Europe", division:2),

    // Italie — Serie A
    .init(name:"Inter Milan", city:"Milan", country:"Italie", continent:"Europe", division:1),
    .init(name:"AC Milan", city:"Milan", country:"Italie", continent:"Europe", division:1),
    .init(name:"Juventus", city:"Turin", country:"Italie", continent:"Europe", division:1),
    .init(name:"AS Rome", city:"Rome", country:"Italie", continent:"Europe", division:1),
    .init(name:"SS Lazio", city:"Rome", country:"Italie", continent:"Europe", division:1),
    .init(name:"Naples", city:"Naples", country:"Italie", continent:"Europe", division:1),
    .init(name:"Atalanta", city:"Bergame", country:"Italie", continent:"Europe", division:1),
    .init(name:"Fiorentina", city:"Florence", country:"Italie", continent:"Europe", division:1),
    .init(name:"Bologne", city:"Bologne", country:"Italie", continent:"Europe", division:1),
    .init(name:"Torino", city:"Turin", country:"Italie", continent:"Europe", division:1),
    .init(name:"Udinese", city:"Udine", country:"Italie", continent:"Europe", division:1),
    .init(name:"Genoa", city:"Gênes", country:"Italie", continent:"Europe", division:1),
    .init(name:"Sassuolo", city:"Sassuolo", country:"Italie", continent:"Europe", division:1),
    .init(name:"Cagliari", city:"Cagliari", country:"Italie", continent:"Europe", division:1),
    .init(name:"Hellas Vérone", city:"Vérone", country:"Italie", continent:"Europe", division:1),
    .init(name:"Empoli", city:"Empoli", country:"Italie", continent:"Europe", division:1),
    .init(name:"Lecce", city:"Lecce", country:"Italie", continent:"Europe", division:1),
    .init(name:"Parme", city:"Parme", country:"Italie", continent:"Europe", division:1),
    .init(name:"Côme", city:"Côme", country:"Italie", continent:"Europe", division:1),
    .init(name:"Venise", city:"Venise", country:"Italie", continent:"Europe", division:1),
    // Italie — Serie B (D2)
    .init(name:"Palerme", city:"Palerme", country:"Italie", continent:"Europe", division:2),
    .init(name:"Sampdoria", city:"Gênes", country:"Italie", continent:"Europe", division:2),
    .init(name:"Bari", city:"Bari", country:"Italie", continent:"Europe", division:2),
    .init(name:"Cremonese", city:"Crémone", country:"Italie", continent:"Europe", division:2),
    .init(name:"Catanzaro", city:"Catanzaro", country:"Italie", continent:"Europe", division:2),
    .init(name:"Spezia", city:"La Spezia", country:"Italie", continent:"Europe", division:2),
    .init(name:"Modène", city:"Modène", country:"Italie", continent:"Europe", division:2),

    // France — Ligue 1
    .init(name:"Paris Saint-Germain", city:"Paris", country:"France", continent:"Europe", division:1),
    .init(name:"AS Monaco", city:"Monaco", country:"France", continent:"Europe", division:1),
    .init(name:"Olympique de Marseille", city:"Marseille", country:"France", continent:"Europe", division:1),
    .init(name:"LOSC Lille", city:"Lille", country:"France", continent:"Europe", division:1),
    .init(name:"Olympique Lyonnais", city:"Lyon", country:"France", continent:"Europe", division:1),
    .init(name:"OGC Nice", city:"Nice", country:"France", continent:"Europe", division:1),
    .init(name:"Stade Rennais", city:"Rennes", country:"France", continent:"Europe", division:1),
    .init(name:"RC Lens", city:"Lens", country:"France", continent:"Europe", division:1),
    .init(name:"Stade de Reims", city:"Reims", country:"France", continent:"Europe", division:1),
    .init(name:"RC Strasbourg", city:"Strasbourg", country:"France", continent:"Europe", division:1),
    .init(name:"Toulouse FC", city:"Toulouse", country:"France", continent:"Europe", division:1),
    .init(name:"FC Nantes", city:"Nantes", country:"France", continent:"Europe", division:1),
    .init(name:"Montpellier HSC", city:"Montpellier", country:"France", continent:"Europe", division:1),
    .init(name:"Angers SCO", city:"Angers", country:"France", continent:"Europe", division:1),
    .init(name:"Le Havre AC", city:"Le Havre", country:"France", continent:"Europe", division:1),
    .init(name:"AJ Auxerre", city:"Auxerre", country:"France", continent:"Europe", division:1),
    .init(name:"Stade Brestois", city:"Brest", country:"France", continent:"Europe", division:1),
    .init(name:"AS Saint-Étienne", city:"Saint-Étienne", country:"France", continent:"Europe", division:1),
    // France — Ligue 2 (D2)
    .init(name:"FC Metz", city:"Metz", country:"France", continent:"Europe", division:2),
    .init(name:"Girondins de Bordeaux", city:"Bordeaux", country:"France", continent:"Europe", division:2),
    .init(name:"Grenoble Foot 38", city:"Grenoble", country:"France", continent:"Europe", division:2),
    .init(name:"Amiens SC", city:"Amiens", country:"France", continent:"Europe", division:2),
    .init(name:"Paris FC", city:"Paris", country:"France", continent:"Europe", division:2),
    .init(name:"En Avant Guingamp", city:"Guingamp", country:"France", continent:"Europe", division:2),
    .init(name:"SM Caen", city:"Caen", country:"France", continent:"Europe", division:2),
    .init(name:"Red Star FC", city:"Saint-Ouen", country:"France", continent:"Europe", division:2),

    // Portugal
    .init(name:"Benfica", city:"Lisbonne", country:"Portugal", continent:"Europe", division:1),
    .init(name:"FC Porto", city:"Porto", country:"Portugal", continent:"Europe", division:1),
    .init(name:"Sporting Portugal", city:"Lisbonne", country:"Portugal", continent:"Europe", division:1),
    .init(name:"SC Braga", city:"Braga", country:"Portugal", continent:"Europe", division:1),
    .init(name:"Vitória de Guimarães", city:"Guimarães", country:"Portugal", continent:"Europe", division:1),
    .init(name:"Boavista", city:"Porto", country:"Portugal", continent:"Europe", division:1),
    .init(name:"Rio Ave", city:"Vila do Conde", country:"Portugal", continent:"Europe", division:1),
    .init(name:"Famalicão", city:"Famalicão", country:"Portugal", continent:"Europe", division:1),

    // Pays-Bas
    .init(name:"Ajax Amsterdam", city:"Amsterdam", country:"Pays-Bas", continent:"Europe", division:1),
    .init(name:"PSV Eindhoven", city:"Eindhoven", country:"Pays-Bas", continent:"Europe", division:1),
    .init(name:"Feyenoord", city:"Rotterdam", country:"Pays-Bas", continent:"Europe", division:1),
    .init(name:"AZ Alkmaar", city:"Alkmaar", country:"Pays-Bas", continent:"Europe", division:1),
    .init(name:"FC Twente", city:"Enschede", country:"Pays-Bas", continent:"Europe", division:1),
    .init(name:"FC Utrecht", city:"Utrecht", country:"Pays-Bas", continent:"Europe", division:1),
    .init(name:"Sparta Rotterdam", city:"Rotterdam", country:"Pays-Bas", continent:"Europe", division:1),

    // Belgique
    .init(name:"Club Bruges", city:"Bruges", country:"Belgique", continent:"Europe", division:1),
    .init(name:"Anderlecht", city:"Bruxelles", country:"Belgique", continent:"Europe", division:1),
    .init(name:"Union Saint-Gilloise", city:"Bruxelles", country:"Belgique", continent:"Europe", division:1),
    .init(name:"Standard de Liège", city:"Liège", country:"Belgique", continent:"Europe", division:1),
    .init(name:"KRC Genk", city:"Genk", country:"Belgique", continent:"Europe", division:1),
    .init(name:"Antwerp FC", city:"Anvers", country:"Belgique", continent:"Europe", division:1),
    .init(name:"Charleroi", city:"Charleroi", country:"Belgique", continent:"Europe", division:1),

    // Turquie
    .init(name:"Galatasaray", city:"Istanbul", country:"Turquie", continent:"Europe", division:1),
    .init(name:"Fenerbahçe", city:"Istanbul", country:"Turquie", continent:"Europe", division:1),
    .init(name:"Besiktas", city:"Istanbul", country:"Turquie", continent:"Europe", division:1),
    .init(name:"Trabzonspor", city:"Trabzon", country:"Turquie", continent:"Europe", division:1),
    .init(name:"Basaksehir", city:"Istanbul", country:"Turquie", continent:"Europe", division:1),
    .init(name:"Konyaspor", city:"Konya", country:"Turquie", continent:"Europe", division:1),

    // Autres nations européennes (une sélection)
    .init(name:"Dynamo Kiev", city:"Kiev", country:"Ukraine", continent:"Europe", division:1),
    .init(name:"Shakhtar Donetsk", city:"Donetsk", country:"Ukraine", continent:"Europe", division:1),
    .init(name:"Dynamo Zagreb", city:"Zagreb", country:"Croatie", continent:"Europe", division:1),
    .init(name:"Hajduk Split", city:"Split", country:"Croatie", continent:"Europe", division:1),
    .init(name:"Étoile Rouge de Belgrade", city:"Belgrade", country:"Serbie", continent:"Europe", division:1),
    .init(name:"Partizan Belgrade", city:"Belgrade", country:"Serbie", continent:"Europe", division:1),
    .init(name:"FC Bâle", city:"Bâle", country:"Suisse", continent:"Europe", division:1),
    .init(name:"Young Boys", city:"Berne", country:"Suisse", continent:"Europe", division:1),
    .init(name:"Rapid Vienne", city:"Vienne", country:"Autriche", continent:"Europe", division:1),
    .init(name:"Austria Vienne", city:"Vienne", country:"Autriche", continent:"Europe", division:1),
    .init(name:"Red Bull Salzbourg", city:"Salzbourg", country:"Autriche", continent:"Europe", division:1),
    .init(name:"FC Copenhague", city:"Copenhague", country:"Danemark", continent:"Europe", division:1),
    .init(name:"Brøndby IF", city:"Brøndby", country:"Danemark", continent:"Europe", division:1),
    .init(name:"Malmö FF", city:"Malmö", country:"Suède", continent:"Europe", division:1),
    .init(name:"AIK Solna", city:"Stockholm", country:"Suède", continent:"Europe", division:1),
    .init(name:"Rosenborg BK", city:"Trondheim", country:"Norvège", continent:"Europe", division:1),
    .init(name:"Sporting Braga B", city:"Braga", country:"Portugal", continent:"Europe", division:2),
    .init(name:"Legia Varsovie", city:"Varsovie", country:"Pologne", continent:"Europe", division:1),
    .init(name:"Lech Poznan", city:"Poznan", country:"Pologne", continent:"Europe", division:1),
    .init(name:"Slavia Prague", city:"Prague", country:"République Tchèque", continent:"Europe", division:1),
    .init(name:"Sparta Prague", city:"Prague", country:"République Tchèque", continent:"Europe", division:1),
    .init(name:"Ferencváros", city:"Budapest", country:"Hongrie", continent:"Europe", division:1),
    .init(name:"Olympiakos", city:"Le Pirée", country:"Grèce", continent:"Europe", division:1),
    .init(name:"Panathinaïkos", city:"Athènes", country:"Grèce", continent:"Europe", division:1),
    .init(name:"AEK Athènes", city:"Athènes", country:"Grèce", continent:"Europe", division:1),
]

private let FDSouthAmericaSeeds: [FDClubSeed] = [
    // Brésil
    .init(name:"Flamengo", city:"Rio de Janeiro", country:"Brésil", continent:"Amérique du Sud", division:1),
    .init(name:"Palmeiras", city:"São Paulo", country:"Brésil", continent:"Amérique du Sud", division:1),
    .init(name:"São Paulo FC", city:"São Paulo", country:"Brésil", continent:"Amérique du Sud", division:1),
    .init(name:"Corinthians", city:"São Paulo", country:"Brésil", continent:"Amérique du Sud", division:1),
    .init(name:"Grêmio", city:"Porto Alegre", country:"Brésil", continent:"Amérique du Sud", division:1),
    .init(name:"Internacional", city:"Porto Alegre", country:"Brésil", continent:"Amérique du Sud", division:1),
    .init(name:"Atlético Mineiro", city:"Belo Horizonte", country:"Brésil", continent:"Amérique du Sud", division:1),
    .init(name:"Cruzeiro", city:"Belo Horizonte", country:"Brésil", continent:"Amérique du Sud", division:1),
    .init(name:"Fluminense", city:"Rio de Janeiro", country:"Brésil", continent:"Amérique du Sud", division:1),
    .init(name:"Botafogo", city:"Rio de Janeiro", country:"Brésil", continent:"Amérique du Sud", division:1),
    .init(name:"Vasco da Gama", city:"Rio de Janeiro", country:"Brésil", continent:"Amérique du Sud", division:1),
    .init(name:"Bahia", city:"Salvador", country:"Brésil", continent:"Amérique du Sud", division:1),
    .init(name:"Fortaleza", city:"Fortaleza", country:"Brésil", continent:"Amérique du Sud", division:1),
    .init(name:"Athletico Paranaense", city:"Curitiba", country:"Brésil", continent:"Amérique du Sud", division:1),
    .init(name:"Santos", city:"Santos", country:"Brésil", continent:"Amérique du Sud", division:2),
    .init(name:"Coritiba", city:"Curitiba", country:"Brésil", continent:"Amérique du Sud", division:2),
    .init(name:"Goiás", city:"Goiânia", country:"Brésil", continent:"Amérique du Sud", division:2),
    .init(name:"Sport Recife", city:"Recife", country:"Brésil", continent:"Amérique du Sud", division:2),
    .init(name:"Ceará SC", city:"Fortaleza", country:"Brésil", continent:"Amérique du Sud", division:2),
    // Argentine
    .init(name:"Boca Juniors", city:"Buenos Aires", country:"Argentine", continent:"Amérique du Sud", division:1),
    .init(name:"River Plate", city:"Buenos Aires", country:"Argentine", continent:"Amérique du Sud", division:1),
    .init(name:"Racing Club", city:"Avellaneda", country:"Argentine", continent:"Amérique du Sud", division:1),
    .init(name:"Independiente", city:"Avellaneda", country:"Argentine", continent:"Amérique du Sud", division:1),
    .init(name:"San Lorenzo", city:"Buenos Aires", country:"Argentine", continent:"Amérique du Sud", division:1),
    .init(name:"Estudiantes de La Plata", city:"La Plata", country:"Argentine", continent:"Amérique du Sud", division:1),
    .init(name:"Gimnasia La Plata", city:"La Plata", country:"Argentine", continent:"Amérique du Sud", division:1),
    .init(name:"Vélez Sarsfield", city:"Buenos Aires", country:"Argentine", continent:"Amérique du Sud", division:1),
    .init(name:"Newell's Old Boys", city:"Rosario", country:"Argentine", continent:"Amérique du Sud", division:1),
    .init(name:"Rosario Central", city:"Rosario", country:"Argentine", continent:"Amérique du Sud", division:1),
    .init(name:"Talleres Córdoba", city:"Córdoba", country:"Argentine", continent:"Amérique du Sud", division:1),
    .init(name:"Argentinos Juniors", city:"Buenos Aires", country:"Argentine", continent:"Amérique du Sud", division:1),
    // Autres nations sud-américaines
    .init(name:"Peñarol", city:"Montevideo", country:"Uruguay", continent:"Amérique du Sud", division:1),
    .init(name:"Nacional", city:"Montevideo", country:"Uruguay", continent:"Amérique du Sud", division:1),
    .init(name:"Defensor Sporting", city:"Montevideo", country:"Uruguay", continent:"Amérique du Sud", division:1),
    .init(name:"Colo-Colo", city:"Santiago", country:"Chili", continent:"Amérique du Sud", division:1),
    .init(name:"Universidad de Chile", city:"Santiago", country:"Chili", continent:"Amérique du Sud", division:1),
    .init(name:"Universidad Católica", city:"Santiago", country:"Chili", continent:"Amérique du Sud", division:1),
    .init(name:"Millonarios", city:"Bogotá", country:"Colombie", continent:"Amérique du Sud", division:1),
    .init(name:"Atlético Nacional", city:"Medellín", country:"Colombie", continent:"Amérique du Sud", division:1),
    .init(name:"América de Cali", city:"Cali", country:"Colombie", continent:"Amérique du Sud", division:1),
    .init(name:"Barcelona SC", city:"Guayaquil", country:"Équateur", continent:"Amérique du Sud", division:1),
    .init(name:"LDU Quito", city:"Quito", country:"Équateur", continent:"Amérique du Sud", division:1),
    .init(name:"Cerro Porteño", city:"Asunción", country:"Paraguay", continent:"Amérique du Sud", division:1),
    .init(name:"Olimpia", city:"Asunción", country:"Paraguay", continent:"Amérique du Sud", division:1),
    .init(name:"The Strongest", city:"La Paz", country:"Bolivie", continent:"Amérique du Sud", division:1),
]

private let FDNorthAmericaSeeds: [FDClubSeed] = [
    // MLS (États-Unis / Canada)
    .init(name:"LA Galaxy", city:"Los Angeles", country:"États-Unis", continent:"Amérique du Nord", division:1),
    .init(name:"LAFC", city:"Los Angeles", country:"États-Unis", continent:"Amérique du Nord", division:1),
    .init(name:"Seattle Sounders", city:"Seattle", country:"États-Unis", continent:"Amérique du Nord", division:1),
    .init(name:"Portland Timbers", city:"Portland", country:"États-Unis", continent:"Amérique du Nord", division:1),
    .init(name:"Inter Miami", city:"Miami", country:"États-Unis", continent:"Amérique du Nord", division:1),
    .init(name:"Atlanta United", city:"Atlanta", country:"États-Unis", continent:"Amérique du Nord", division:1),
    .init(name:"New York City FC", city:"New York", country:"États-Unis", continent:"Amérique du Nord", division:1),
    .init(name:"New York Red Bulls", city:"Harrison", country:"États-Unis", continent:"Amérique du Nord", division:1),
    .init(name:"Columbus Crew", city:"Columbus", country:"États-Unis", continent:"Amérique du Nord", division:1),
    .init(name:"FC Cincinnati", city:"Cincinnati", country:"États-Unis", continent:"Amérique du Nord", division:1),
    .init(name:"Chicago Fire", city:"Chicago", country:"États-Unis", continent:"Amérique du Nord", division:1),
    .init(name:"Sporting Kansas City", city:"Kansas City", country:"États-Unis", continent:"Amérique du Nord", division:1),
    .init(name:"Real Salt Lake", city:"Salt Lake City", country:"États-Unis", continent:"Amérique du Nord", division:1),
    .init(name:"Philadelphia Union", city:"Philadelphie", country:"États-Unis", continent:"Amérique du Nord", division:1),
    .init(name:"Austin FC", city:"Austin", country:"États-Unis", continent:"Amérique du Nord", division:1),
    .init(name:"Nashville SC", city:"Nashville", country:"États-Unis", continent:"Amérique du Nord", division:1),
    .init(name:"Toronto FC", city:"Toronto", country:"Canada", continent:"Amérique du Nord", division:1),
    .init(name:"CF Montréal", city:"Montréal", country:"Canada", continent:"Amérique du Nord", division:1),
    .init(name:"Vancouver Whitecaps", city:"Vancouver", country:"Canada", continent:"Amérique du Nord", division:1),
    // Mexique — Liga MX
    .init(name:"Club América", city:"Mexico", country:"Mexique", continent:"Amérique du Nord", division:1),
    .init(name:"Chivas Guadalajara", city:"Guadalajara", country:"Mexique", continent:"Amérique du Nord", division:1),
    .init(name:"Cruz Azul", city:"Mexico", country:"Mexique", continent:"Amérique du Nord", division:1),
    .init(name:"Pumas UNAM", city:"Mexico", country:"Mexique", continent:"Amérique du Nord", division:1),
    .init(name:"Tigres UANL", city:"Monterrey", country:"Mexique", continent:"Amérique du Nord", division:1),
    .init(name:"Monterrey", city:"Monterrey", country:"Mexique", continent:"Amérique du Nord", division:1),
    .init(name:"Toluca", city:"Toluca", country:"Mexique", continent:"Amérique du Nord", division:1),
    .init(name:"Santos Laguna", city:"Torreón", country:"Mexique", continent:"Amérique du Nord", division:1),
    .init(name:"León", city:"León", country:"Mexique", continent:"Amérique du Nord", division:1),
    .init(name:"Pachuca", city:"Pachuca", country:"Mexique", continent:"Amérique du Nord", division:1),
    // Autres nations d'Amérique centrale / Caraïbes
    .init(name:"Alajuelense", city:"Alajuela", country:"Costa Rica", continent:"Amérique du Nord", division:1),
    .init(name:"Saprissa", city:"San José", country:"Costa Rica", continent:"Amérique du Nord", division:1),
    .init(name:"Cavalier FC", city:"Kingston", country:"Jamaïque", continent:"Amérique du Nord", division:1),
]

private let FDAsiaSeeds: [FDClubSeed] = [
    // Japon — J1 League
    .init(name:"Kashima Antlers", city:"Kashima", country:"Japon", continent:"Asie", division:1),
    .init(name:"Urawa Red Diamonds", city:"Saitama", country:"Japon", continent:"Asie", division:1),
    .init(name:"Yokohama F. Marinos", city:"Yokohama", country:"Japon", continent:"Asie", division:1),
    .init(name:"Kawasaki Frontale", city:"Kawasaki", country:"Japon", continent:"Asie", division:1),
    .init(name:"Vissel Kobe", city:"Kobe", country:"Japon", continent:"Asie", division:1),
    .init(name:"Gamba Osaka", city:"Osaka", country:"Japon", continent:"Asie", division:1),
    .init(name:"Cerezo Osaka", city:"Osaka", country:"Japon", continent:"Asie", division:1),
    .init(name:"FC Tokyo", city:"Tokyo", country:"Japon", continent:"Asie", division:1),
    .init(name:"Nagoya Grampus", city:"Nagoya", country:"Japon", continent:"Asie", division:1),
    .init(name:"Sanfrecce Hiroshima", city:"Hiroshima", country:"Japon", continent:"Asie", division:1),
    // Corée du Sud — K League 1
    .init(name:"Ulsan HD", city:"Ulsan", country:"Corée du Sud", continent:"Asie", division:1),
    .init(name:"Jeonbuk Hyundai Motors", city:"Jeonju", country:"Corée du Sud", continent:"Asie", division:1),
    .init(name:"Pohang Steelers", city:"Pohang", country:"Corée du Sud", continent:"Asie", division:1),
    .init(name:"FC Séoul", city:"Séoul", country:"Corée du Sud", continent:"Asie", division:1),
    .init(name:"Suwon Samsung Bluewings", city:"Suwon", country:"Corée du Sud", continent:"Asie", division:1),
    .init(name:"Daegu FC", city:"Daegu", country:"Corée du Sud", continent:"Asie", division:1),
    // Arabie Saoudite — Pro League
    .init(name:"Al-Hilal", city:"Riyad", country:"Arabie Saoudite", continent:"Asie", division:1),
    .init(name:"Al-Nassr", city:"Riyad", country:"Arabie Saoudite", continent:"Asie", division:1),
    .init(name:"Al-Ittihad", city:"Djeddah", country:"Arabie Saoudite", continent:"Asie", division:1),
    .init(name:"Al-Ahli", city:"Djeddah", country:"Arabie Saoudite", continent:"Asie", division:1),
    .init(name:"Al-Ettifaq", city:"Dammam", country:"Arabie Saoudite", continent:"Asie", division:1),
    .init(name:"Al-Shabab", city:"Riyad", country:"Arabie Saoudite", continent:"Asie", division:1),
    // Chine — Super League
    .init(name:"Shanghai Port", city:"Shanghai", country:"Chine", continent:"Asie", division:1),
    .init(name:"Shanghai Shenhua", city:"Shanghai", country:"Chine", continent:"Asie", division:1),
    .init(name:"Beijing Guoan", city:"Pékin", country:"Chine", continent:"Asie", division:1),
    .init(name:"Shandong Taishan", city:"Jinan", country:"Chine", continent:"Asie", division:1),
    .init(name:"Zhejiang FC", city:"Hangzhou", country:"Chine", continent:"Asie", division:1),
    // Autres nations asiatiques
    .init(name:"Al-Sadd", city:"Doha", country:"Qatar", continent:"Asie", division:1),
    .init(name:"Al-Duhail", city:"Doha", country:"Qatar", continent:"Asie", division:1),
    .init(name:"Al-Ain", city:"Al Ain", country:"Émirats Arabes Unis", continent:"Asie", division:1),
    .init(name:"Al-Wahda", city:"Abou Dabi", country:"Émirats Arabes Unis", continent:"Asie", division:1),
    .init(name:"Persib Bandung", city:"Bandung", country:"Indonésie", continent:"Asie", division:1),
    .init(name:"Buriram United", city:"Buriram", country:"Thaïlande", continent:"Asie", division:1),
]

private let FDAfricaSeeds: [FDClubSeed] = [
    // Maroc
    .init(name:"Raja Casablanca", city:"Casablanca", country:"Maroc", continent:"Afrique", division:1),
    .init(name:"Wydad Casablanca", city:"Casablanca", country:"Maroc", continent:"Afrique", division:1),
    .init(name:"FAR Rabat", city:"Rabat", country:"Maroc", continent:"Afrique", division:1),
    .init(name:"AS FAR", city:"Rabat", country:"Maroc", continent:"Afrique", division:1),
    .init(name:"Renaissance de Berkane", city:"Berkane", country:"Maroc", continent:"Afrique", division:1),
    // Égypte
    .init(name:"Al Ahly", city:"Le Caire", country:"Égypte", continent:"Afrique", division:1),
    .init(name:"Zamalek", city:"Le Caire", country:"Égypte", continent:"Afrique", division:1),
    .init(name:"Pyramids FC", city:"Le Caire", country:"Égypte", continent:"Afrique", division:1),
    .init(name:"Al Ittihad Alexandrie", city:"Alexandrie", country:"Égypte", continent:"Afrique", division:1),
    // Tunisie
    .init(name:"Espérance de Tunis", city:"Tunis", country:"Tunisie", continent:"Afrique", division:1),
    .init(name:"Club Africain", city:"Tunis", country:"Tunisie", continent:"Afrique", division:1),
    .init(name:"Étoile du Sahel", city:"Sousse", country:"Tunisie", continent:"Afrique", division:1),
    .init(name:"CS Sfaxien", city:"Sfax", country:"Tunisie", continent:"Afrique", division:1),
    // Algérie
    .init(name:"CR Belouizdad", city:"Alger", country:"Algérie", continent:"Afrique", division:1),
    .init(name:"USM Alger", city:"Alger", country:"Algérie", continent:"Afrique", division:1),
    .init(name:"ES Sétif", city:"Sétif", country:"Algérie", continent:"Afrique", division:1),
    .init(name:"JS Kabylie", city:"Tizi Ouzou", country:"Algérie", continent:"Afrique", division:1),
    // Sénégal
    .init(name:"Casa Sports", city:"Ziguinchor", country:"Sénégal", continent:"Afrique", division:1),
    .init(name:"Génération Foot", city:"Déni Biram Ndao", country:"Sénégal", continent:"Afrique", division:1),
    .init(name:"AS Douanes", city:"Dakar", country:"Sénégal", continent:"Afrique", division:1),
    .init(name:"Jaraaf de Dakar", city:"Dakar", country:"Sénégal", continent:"Afrique", division:1),
    // Nigeria
    .init(name:"Enyimba", city:"Aba", country:"Nigeria", continent:"Afrique", division:1),
    .init(name:"Rivers United", city:"Port Harcourt", country:"Nigeria", continent:"Afrique", division:1),
    .init(name:"Kano Pillars", city:"Kano", country:"Nigeria", continent:"Afrique", division:1),
    .init(name:"Remo Stars", city:"Ikenne", country:"Nigeria", continent:"Afrique", division:1),
    // Afrique du Sud
    .init(name:"Mamelodi Sundowns", city:"Pretoria", country:"Afrique du Sud", continent:"Afrique", division:1),
    .init(name:"Orlando Pirates", city:"Johannesbourg", country:"Afrique du Sud", continent:"Afrique", division:1),
    .init(name:"Kaizer Chiefs", city:"Johannesbourg", country:"Afrique du Sud", continent:"Afrique", division:1),
    .init(name:"SuperSport United", city:"Pretoria", country:"Afrique du Sud", continent:"Afrique", division:1),
    // Autres
    .init(name:"TP Mazembe", city:"Lubumbashi", country:"RD Congo", continent:"Afrique", division:1),
    .init(name:"AS Vita Club", city:"Kinshasa", country:"RD Congo", continent:"Afrique", division:1),
    .init(name:"Simba SC", city:"Dar es Salaam", country:"Tanzanie", continent:"Afrique", division:1),
    .init(name:"Young Africans", city:"Dar es Salaam", country:"Tanzanie", continent:"Afrique", division:1),
    .init(name:"Coton Sport de Garoua", city:"Garoua", country:"Cameroun", continent:"Afrique", division:1),
    .init(name:"Union Douala", city:"Douala", country:"Cameroun", continent:"Afrique", division:1),
]

private let FDOceaniaSeeds: [FDClubSeed] = [
    .init(name:"Melbourne City", city:"Melbourne", country:"Australie", continent:"Océanie", division:1),
    .init(name:"Melbourne Victory", city:"Melbourne", country:"Australie", continent:"Océanie", division:1),
    .init(name:"Sydney FC", city:"Sydney", country:"Australie", continent:"Océanie", division:1),
    .init(name:"Western Sydney Wanderers", city:"Sydney", country:"Australie", continent:"Océanie", division:1),
    .init(name:"Adelaide United", city:"Adélaïde", country:"Australie", continent:"Océanie", division:1),
    .init(name:"Perth Glory", city:"Perth", country:"Australie", continent:"Océanie", division:1),
    .init(name:"Brisbane Roar", city:"Brisbane", country:"Australie", continent:"Océanie", division:1),
    .init(name:"Wellington Phoenix", city:"Wellington", country:"Nouvelle-Zélande", continent:"Océanie", division:1),
    .init(name:"Auckland City", city:"Auckland", country:"Nouvelle-Zélande", continent:"Océanie", division:1),
]

let FDAllClubSeeds: [FDClubSeed] =
    FDEuropeSeeds + FDSouthAmericaSeeds + FDNorthAmericaSeeds + FDAsiaSeeds + FDAfricaSeeds + FDOceaniaSeeds

// MARK: - Procedural stat derivation (deterministic hash → stable jitter)

private func fdStableJitter(_ seed: String, range: ClosedRange<Int>) -> Int {
    var hash: UInt64 = 5381
    for byte in seed.utf8 { hash = ((hash << 5) &+ hash) &+ UInt64(byte) }
    let span = range.upperBound - range.lowerBound + 1
    return range.lowerBound + Int(hash % UInt64(span))
}

func fdBuildClub(from seed: FDClubSeed) -> FDClub {
    let tier = FDCountryTier[seed.country] ?? 3
    let divisionPenalty = (seed.division - 1) * 16
    let tierPenalty = (tier - 1) * 9
    let jitter = fdStableJitter(seed.name, range: -5...5)

    let reputation = max(20, min(96, 88 - divisionPenalty - tierPenalty + jitter))
    let academy = max(25, min(95, reputation + fdStableJitter(seed.name + "a", range: -12...10)))
    let youthMinutes = max(20, min(90, 100 - reputation + fdStableJitter(seed.name + "m", range: -10...10)))

    let slug = (seed.name + "-" + seed.city)
        .folding(options: .diacriticInsensitive, locale: .current)
        .lowercased()
        .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)

    return FDClub(
        id: slug,
        name: seed.name,
        city: seed.city,
        country: seed.country,
        continent: seed.continent,
        division: seed.division,
        reputation: reputation,
        academyQuality: academy,
        youthMinutes: youthMinutes
    )
}

let FDAllClubs: [FDClub] = FDAllClubSeeds.map(fdBuildClub)

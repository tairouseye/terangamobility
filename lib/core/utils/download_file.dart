// Telecharge / enregistre une image dans un nouvel onglet.
//
// Les photos Encar sont servies sans en-tete CORS : impossible d'en recuperer
// les octets cote client pour forcer un vrai telechargement. Le mieux possible
// est donc d'ouvrir la photo pleine resolution (l'utilisateur l'enregistre via
// « clic droit / appui long -> Enregistrer l'image »). Sur le web on utilise
// une balise <a download> qui declenche l'enregistrement quand c'est permis,
// et ouvre l'onglet sinon.
export 'download_file_io.dart'
    if (dart.library.js_interop) 'download_file_web.dart';

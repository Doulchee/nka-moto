# Mettre N'ka Moto en ligne (gratuit)

## 1. GitHub
Crée un dépôt `nka-moto` et pousse le dossier.

## 2. Base de données (Neon, gratuit)
1. Va sur https://neon.tech et crée un projet.
2. Copie la `DATABASE_URL` (elle commence par `postgresql://`).

## 3. API (Render, gratuit)
1. Va sur https://render.com et connecte ton GitHub.
2. Nouveau Web Service → choisis le dépôt → dossier `nka-moto-backend`.
3. Build : `npm install && npx prisma generate && npm run build`
4. Start : `npx prisma db push && npm run start`
5. Ajoute les variables :
   - `DATABASE_URL` = celle de Neon
   - `JWT_ACCESS_SECRET` = une longue chaîne aléatoire
   - `JWT_REFRESH_SECRET` = une autre
   - `CHASSIS_ENCRYPTION_KEY` = une autre
6. Déploie. Note l’URL (ex. `https://nka-moto-api.onrender.com`).

## 4. Site web (Netlify, gratuit)
Dans le dossier app :
```
flutter build web --dart-define=API_URL=https://nka-moto-api.onrender.com
```
Puis sur Netlify : glisse le dossier `build/web`.

## 5. Admin
Ouvre `nka-moto-admin/index.html` et change la ligne :
```js
const API = 'https://nka-moto-api.onrender.com';
```
Tu peux aussi l’héberger sur Netlify.

## Notes
- Le serveur gratuit s’endort. Le premier clic peut prendre 30 secondes.
- Pas de vrai SMS. On reste sur téléphone + mot de passe.
- Pour créer l’admin après déploiement : dans Render, Shell → `npm run seed:admin`

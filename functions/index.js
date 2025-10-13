const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors")({origin: true});

admin.initializeApp();

exports.generateResetLink = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method !== "POST") {
      return res.status(405).send("Método não permitido");
    }

    const {email} = req.body;
    if (!email) {
      return res.status(400).json({error: "Email obrigatório"});
    }

    try {
      const link = await admin.auth().generatePasswordResetLink(email, {
        url: "https://manoamano.pagali.cv/reset",
        handleCodeInApp: true,
      });
      return res.status(200).json({resetLink: link});
    } catch (error) {
      console.error("Erro ao gerar link de reset:", error);
      return res.status(500).json({error: error.message});
    }
  });
});

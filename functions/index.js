const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const nodemailer = require('nodemailer');

initializeApp();

// Configure nodemailer with Gmail credentials
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'maijason112102@gmail.com',
    pass: 'jrdf rulv vydy doou'
  }
});

exports.sendVerificationEmail = onDocumentCreated('verificationCodes/{email}', async (event) => {
  const snapshot = event.data;
  const email = event.params.email;
  const code = snapshot.data().code;

  const mailOptions = {
    from: 'maijason112102@gmail.com',
    to: email,
    subject: 'UniMarket Student Email Verification',
    html: `
      <h1>UniMarket Student Email Verification</h1>
      <p>Your verification code is: <strong>${code}</strong></p>
      <p>This code will expire in 10 minutes.</p>
      <p>If you did not request this verification code, please ignore this email.</p>
    `
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log('Verification email sent successfully to:', email);
  } catch (error) {
    console.error('Error sending verification email:', error);
    throw new Error('Failed to send verification email');
  }
}); 
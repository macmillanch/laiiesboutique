const cloudinary = require('cloudinary').v2;
const multer = require('multer');
const { Readable } = require('stream');

// Configure Cloudinary
cloudinary.config({
    cloud_name: 'du7xm2eqi',
    api_key: '316611551525272',
    api_secret: 'K8nwReABUWlOYZpTU0fS0nfTqrw'
});

// Configure Multer (Memory Storage)
const storage = multer.memoryStorage();
const upload = multer({ storage: storage });

// Helper function to upload buffer to Cloudinary
const uploadToCloudinary = (buffer) => {
    return new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
            { folder: "ladies-boutique" }, // Optional: organize in a folder
            (error, result) => {
                if (error) return reject(error);
                resolve(result);
            }
        );

        const readableStream = new Readable();
        readableStream.push(buffer);
        readableStream.push(null);
        readableStream.pipe(stream);
    });
};

module.exports = {
    upload,
    uploadToCloudinary
};

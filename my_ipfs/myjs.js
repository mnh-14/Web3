const Moralis = require("moralis").default
const fs = require("fs")
require("dotenv").config();

async function upload_file(name, path_to_img){
    file_to_upload = [
        {
            path: name,
            content: fs.readFileSync(path_to_img, {encoding: "base64"})
        }
    ]
    await Moralis.start({
        apiKey: process.env.MORALIS_KEY
    })

    const response = await Moralis.EvmApi.ipfs.uploadFolder({abi: file_to_upload})
    return response.result[0].path
}
  
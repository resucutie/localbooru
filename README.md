# LocalBooru
Your personal booru collection

This is a cross platform local booru collection that exclusively works on your local storage, without selfhosting.

## Targetted platforms
- Android
- Linux
- Windows
- macOS

### Planned platforms
- iOS (Sideloading)

## Install
### Windows
You will need the [Microsoft Visual C++ Redistributable](https://aka.ms/vs/17/release/vc_redist.x64.exe) installed for using this program.  
After doing that, go and download the setup wizard file over at [Releases](https://github.com/resucutie/localbooru/releases/latest)

### macOS
Download `localbooru-macos.zip` over at [Releases](https://github.com/resucutie/localbooru/releases/latest), extract its file contents and grab the LocalBooru.app file

### Linux
There are prebuilt .deb and .rpm packages over at [Releases](https://github.com/resucutie/localbooru/releases/latest), but you can download the binaries if you want. Flatpak support is planned as of writing

### Android
Download `localbooru-android.apk` over at [Releases](https://github.com/resucutie/localbooru/releases/latest) and install it by opening the file

You can use [Obtanium](https://github.com/ImranR98/Obtainium) if you want an update manager


## FAQ
### How does the versioning work?
For the number, the first number is fixed to "1" unless the whole program gets rewritten. The second number is the major version, reserved for when new features come out, and the third is the minor, reserved for bug fixes.

For the names, the versions are named based on any artist's name that we deem good enough to homenage. For bug fix versions, the name won't be updated  
Some of the parameters that we choose to homenage are:
- Good or outstanding art style (always try to be better)
- Makes inovating and constructive art
- Does not interact with drama on a frequent basis (everyone hates drama lets be real)
- Great person overall

### What is a booru?
A booru is a collection of images that are organized by multiple tags, so you can check specific artwork that you desire. It also has the benefit to preserve the image sources and as such increase discoverability

### How does the autotagging works?
Easy: it just fetches [Danbooru's autotagger](https://autotagger.donmai.us/). Including the autotagger inside the application is a no-go because it will require installing depedencies such as python on the project, and will increase a lot the application's size. If you want to make it work

### Can I import my previous image collection?
Not so easily. The main issue is with adding tags, as it fetches a website to do that. You can make it exclusively local by selfhosting the autotagger and pointing

### What are the avaiable search methods?
`tag` - Exclude every image without that tag  
`-tag` - Exclude every image with that tag  
`+tag` - Includes every image with that tag  

### Which services can it autoimport from?
- Danbooru 2
- Danbooru 1 (Moebooru)
- e621/e926
- Gelbooru 0.2.0 to 0.2.5
- Twitter (using [fxtwitter](https://fxtwitter.com) to gather data)
- Fur Affinity ((using [fxraffinity](https://fxraffinity.net) to gather data)
- Deviantart
- Any URL that returns an image or video

We still have to add:
- Pixiv (we cant obtain the data using its API without log in information and we cant webscrap it because of it blocking NSFW content)
- Gelbooru 0.1 (not a necessity, the reason that it is considered is because rule34.us is the only popular website that uses 0.1)

## To-do
- [ ] Packaging stuff
    - [x] RPM
    - [x] DEB
    - [ ] Flatpak support
    - [ ] Change iOS and macOS icons
    - [ ] F-droid
    - [ ] AltStore (maybe)
- [x] Organize alphabetically the tag list
- [x] Auto tag generation
- [x] Update checker for the app
- [x] Tag classification (separate by author, character...)
- [x] Auto-import from other booru websites (and Twitter)
- [ ] Mass import from local image collections
- [x] Tag suggestion
- [x] Material You
- [ ] Support for multiple file formats
- [ ] Multi booru support
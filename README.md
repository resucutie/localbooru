<p align="center"><img src="assets/promotional/banner + screenshot.png"/></p>

<p align="center">
    Your personal booru collection
</p>
<p align="center">
    This is a cross platform local booru collection that exclusively works on your local storage, without selfhosting.
</p>
<p align="center">
    <img src="https://img.shields.io/github/issues/resucutie/localbooru?style=for-the-badge&color=673AB7"/>
    <img src="https://img.shields.io/github/issues-pr/resucutie/localbooru?style=for-the-badge&color=673AB7"/>
</p>
<p align="center">
    <a href="https://en.liberapay.com/resucutie"><img src="https://img.shields.io/liberapay/receives/resucutie?style=for-the-badge&logo=liberapay"/></a>
    <a href="https://github.com/sponsors/resucutie"><img src="https://img.shields.io/github/sponsors/resucutie?style=for-the-badge&logo=githubsponsors&color=EA4AAA"/></a>
    <a href="https://discord.gg/D5kdKePY52"><img src="https://img.shields.io/badge/check%20our%20discord%20server-673AB7?style=for-the-badge"/></a>
</p>


## Targetted platforms
- Windows
- Android
- Linux
  - [AUR](https://aur.archlinux.org/packages/localbooru) (`localbooru`) ![AUR](https://img.shields.io/aur/version/localbooru)
  - [NUR](https://github.com/ixhbinphoenix/nur-packages) (`nur.repos.ixhbinphoenix.localbooru-bin`)

### Planned platforms
- macOS
- iOS (Sideloading)

## Install
### Windows
You will need the [Microsoft Visual C++ Redistributable](https://aka.ms/vs/17/release/vc_redist.x64.exe) installed for using this program.  
After doing that, go and download the setup wizard file over at [Releases](https://github.com/resucutie/localbooru/releases/latest)

<!-- ### macOS
Download `localbooru-macos.zip` over at [Releases](https://github.com/resucutie/localbooru/releases/latest), extract its file contents and grab the LocalBooru.app file -->

### Linux
There are prebuilt .deb and .rpm packages over at [Releases](https://github.com/resucutie/localbooru/releases/latest), but you can download the binaries if you want. Flatpak support is planned as of writing  

The package is avaiable on the [AUR](https://aur.archlinux.org/packages/localbooru) and on the NUR (`nur.repos.ixhbinphoenix.localbooru-bin`)


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
A booru is a collection of images that are organized by multiple tags, so you can check specific artwork that you desire. It also has the benefit to preserve the image sources and as such increase discoverability.

On LocalBooru, we call a booru a folder made by LocalBooru that contains all the images and the tags stored.

### How does the autotagging works?
Easy: it just fetches [Danbooru's autotagger](https://autotagger.donmai.us/). Including the autotagger inside the application is a no-go because it will require installing depedencies such as python on the project, and will increase a lot the application's size. If you're wondering why is it that imprecise, blame them.

### Can I import my previous image collection?
Not so easily. The main issue is with adding tags, and files do not come with tags built in. You have to manually add the images at the moment. Due to how unreliable autotagging is, it is for the best to not include at the moment a way to automate it

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
- Fur Affinity (using [fxraffinity](https://fxraffinity.net) to gather data)
- Deviantart
- Any URL that returns an image or video

We still have to add:
- Pixiv (we cant obtain the data using its API without log in information and we cant webscrap it because of it blocking NSFW content)
- Instagram
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
- [x] Support for multiple file formats
- [ ] Multi booru support

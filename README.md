# LocalBooru
Your personal booru collection

This is a cross platform local booru collection that exclusively works on your local storage, without selfhosting. Will require importing

## Targetted platforms
- Android (F-droid)
- Linux
- Windows
- macOS
- iOS (Sideloading)

## FAQ
### Why the copy button is only avaiable on desktop?
No. The clipboard manager that we (a.k.a. the only dev here) use, [pasteboard](https://pub.dev/packages/pasteboard), cannot copy images on mobile devices, only on desktop ones. If anyone has any replacement for it that can actually copy images (we are looking at you [super_clipboard](https://pub.dev/packages/super_clipboard)) for at least any of the mobile platforms we will happily include. For now mobile users are limited to opening and sharing files.  
As the "hotfix" solution for Android users, you can use [an share to clipboard app](https://f-droid.org/en/packages/com.kpstv.xclipper/)

### How does the versioning work?
For the number, the first number is fixed to "1" unless the whole program gets rewritten. The second number is the major version, reserved for when new features come out, and the third is the minor, reserved for bug fixes.

For the names, the versions are named based on any artist's name that we deem enough to homenage.  
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
Not so easily. Creating

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
- [ ] Update checker for the app
- [ ] Tag classification (separate by author, character...)
- [ ] Auto-import from other booru websites (and Twitter)
- [ ] Auto import from local repos
- [ ] Tag suggestion
- [x] Material You
- [ ] Multi booru support
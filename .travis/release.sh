#! /bin/bash

# Install github_changelog_generator
gem install github_changelog_generator

# Get latest (soon to be previous) release
previous_release_tag=$(curl -s \
-u ${GITHUB_USERNAME}:${GITHUB_ACCESS_TOKEN} \
https://api.github.com/repos/${GITHUB_USERNAME}/test-minishift-travis/releases/latest | \
    jq -r .tag_name)

# Create GitHub release
release_name="${TRAVIS_TAG:1}"
github_changelog_generator -t ${GITHUB_ACCESS_TOKEN} -o /tmp/CHANGELOG.md --since-tag ${previous_release_tag}
release_changelog=$(< /tmp/CHANGELOG.md)
jq -n \
--arg tag_name "$TRAVIS_TAG" \
--arg release_name "$release_name" \
--arg release_changelog "$release_changelog" \
'{
    "tag_name": $tag_name,
    "name": $release_name,
    "body": $release_changelog,
    "draft": false,
    "prerelease": false
}' |
curl -i \
    -u ${GITHUB_USERNAME}:${GITHUB_ACCESS_TOKEN} \
    -d@- \
    https://api.github.com/repos/${GITHUB_USERNAME}/test-minishift-travis/releases

# Generate CHANGELOG.md
github_changelog_generator -t ${GITHUB_ACCESS_TOKEN}

# Commit and push the CHANGELOG
git config --global user.email "builds@travis-ci.com"
git config --global user.name "Travis CI"
git remote rm origin
git remote add origin https://${GITHUB_USERNAME}:${GITHUB_ACCESS_TOKEN}@github.com/${GITHUB_USERNAME}/test-minishift-travis.git      
git add CHANGELOG.md
git commit -m "Add CHANGELOG [ci skip]" && git push origin HEAD:master          

# mvn deploy to Bintray
./mvnw -s .travis/settings.xml -DskipTests=true -DperformRelease=true deploy"
function buildParents(String entry)
        => let (parents = entry.split('/'.equals).filter(not(String.empty)).exceptLast)
    if (exists firstParent = parents.first)
    then
        if (nonempty restOfParents = parents.rest.sequence())
        then restOfParents.scan(firstParent + "/")(
                (path, nextParent) => "".join { path, nextParent + "/" })
        else { firstParent + "/" }
    else {};

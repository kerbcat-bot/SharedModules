require( 'strict' )

local i18n = {}

local metatable = {}
local methodtable = {}

metatable.__index = methodtable

local libraryUtil = require( 'libraryUtil' )
local checkType = libraryUtil.checkType

--- Cache table containing i18n data
--- e.g. cache['en']['SMW'] will get you the SMW table in English
local cache = {}


--- Retrieve dataset namespace from key prefix
---
--- @param key string The translation key
--- @return string
local function getNamespace( key )
    local namespace = string.match( key, '([^_]*)' )
    return namespace
end


--- Retrieve a list of applicable language codes
---
--- @return table
local function getLanguageCodes()
    local mwlang = mw.language.getContentLanguage()
    local langCodes = { mwlang:getCode() }

    local fallbackLangCodes = mwlang:getFallbackLanguages()
    if next( fallbackLangCodes ) ~= nil then
        for _, fallbackLangCode in pairs( fallbackLangCodes ) do
            table.insert( langCodes, fallbackLangCode )
        end
    end
    return langCodes
end


--- Loads a dataset and saves it to the cache
---
--- @param lang string
--- @param namespace string
--- @return table|nil { data = "The dataset", keys = "Translation key mapped to index" }
local function load( lang, namespace )
    if cache[ lang ] and cache[ lang ][ namespace ] then
        mw.log( string.format( 'Dataset[%s][%s]: Cache HIT', lang, namespace ) )
        return cache[ lang ][ namespace ]
    end

    local success, data = pcall( mw.loadJsonData, string.format( 'Module:i18n/%s/%s.json', namespace, lang ) )

    if not success then
        mw.log( string.format( 'Dataset[%s][%s]: Not found on wiki', lang, namespace ) )
        return
    end

    if not cache[ lang ] then
        cache[ lang ] = {}
    end

    cache[ lang ][ namespace ] = data
    mw.log( string.format( 'Dataset[%s][%s]: Cache CREATED', lang, namespace ) )

    return cache[ lang ][ namespace ]
end


--- Returns translated message
---
--- @param key string The translation key
--- @return string If the key was not found in the i18n table, the key is returned
function methodtable.translate( self, key )
    checkType( 'Module:i18n.translate', 1, self, 'table' )
    checkType( 'Module:i18n.translate', 2, key, 'string' )

    local namespace = getNamespace( key )
    if namespace == nil then
        -- No namespace found error
        return key
    end

    local message
    local languages = getLanguageCodes()
    local i = 1
    while ( message == nil and i <= #languages ) do
        local dataset = load( languages[ i ], namespace )
        if dataset then
            local match = dataset[ key ]
            if match then
                message = match
            end
        end
        i = i + 1
    end
    return message or key
end


--- New Instance
---
--- @return table i18n
function i18n.new( self )
    local instance = {}

    setmetatable( instance, metatable )

    return instance
end


return i18n
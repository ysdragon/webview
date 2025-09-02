/*
    Language: Ring
    Description: Ring programming language syntax highlighting
    Website: https://ring-lang.net/
    Author: Youssef Saeed
*/

function ring(hljs) {
  const KEYWORDS = {
    // Control flow keywords
    keyword: [
      'if', 'but', 'elseif', 'else', 'other', 'ok', 'endif', 'end',
      'switch', 'on', 'case', 'off', 'endswitch',
      'for', 'in', 'to', 'step', 'next', 'endfor', 'foreach',
      'while', 'endwhile',
      'do', 'again',
      'return', 'bye',
      'exit', 'break', 'loop', 'continue',
      'call',
      // Exception handling
      'try', 'catch', 'done', 'endtry',
      // I/O keywords
      'see', 'put', 'give', 'get'
    ],
    
    // Declaration keywords
    'keyword.declaration': [
      'class', 'endclass', 'from',
      'func', 'def', 'function', 'endfunc', 'endfunction',
      'package', 'endpackage', 'private'
    ],
    
    // Module/namespace keywords
    'keyword.namespace': [
      'load', 'import'
    ],
    
    // OOP keywords
    'keyword.pseudo': [
      'new', 'self', 'this', 'super'
    ],
    
    // Logical operators
    'operator.word': [
      'and', 'or', 'not'
    ],
    
    // Built-in variables and constants
    built_in: [
      'true', 'false', 'nl', 'null', 'tab', 'cr', 'sysargv', 'ccatcherror',
      'ringoptionalfunctions'
    ]
  };

  const SCANNER_COMMANDS = [
    'changeringkeyword', 'changeringoperator', 'disablehashcomments',
    'enablehashcomments', 'loadsyntax'
  ];

  const BUILTIN_FUNCTIONS = [
    'acos', 'add', 'addattribute', 'adddays', 'addmethod', 'ascii', 'asin',
    'assert', 'atan', 'atan2', 'attributes', 'binarysearch', 'bytes2double',
    'bytes2float', 'bytes2int', 'callgarbagecollector', 'callgc', 'ceil',
    'cfunctions', 'char', 'chdir', 'checkoverflow', 'classes', 'classname',
    'clearerr', 'clock', 'clockspersecond', 'closelib', 'copy', 'cos',
    'cosh', 'currentdir', 'date', 'dec', 'decimals', 'del', 'diffdays',
    'dir', 'direxists', 'double2bytes', 'eval', 'exefilename', 'exefolder',
    'exp', 'fabs', 'fclose', 'feof', 'ferror', 'fexists', 'fflush',
    'fgetc', 'fgetpos', 'fgets', 'filename', 'find', 'float2bytes',
    'floor', 'fopen', 'fputc', 'fputs', 'fread', 'freopen', 'fseek',
    'fsetpos', 'ftell', 'functions', 'fwrite', 'getarch', 'getattribute',
    'getchar', 'getfilesize', 'getnumber', 'getpathtype', 'getpointer',
    'getptr', 'getstring', 'globals', 'hex', 'hex2str', 'importpackage',
    'input', 'insert', 'int2bytes', 'intvalue', 'isalnum', 'isalpha',
    'isandroid', 'isattribute', 'iscfunction', 'isclass', 'iscntrl',
    'isdigit', 'isfreebsd', 'isfunction', 'isglobal', 'isgraph',
    'islinux', 'islist', 'islocal', 'islower', 'ismacosx', 'ismethod',
    'ismsdos', 'isnull', 'isnumber', 'isobject', 'ispackage',
    'ispackageclass', 'ispointer', 'isprint', 'isprivateattribute',
    'isprivatemethod', 'ispunct', 'isspace', 'isstring', 'isunix',
    'isupper', 'iswindows', 'iswindows64', 'isxdigit', 'left', 'len',
    'lines', 'list', 'list2str', 'loadlib', 'locals', 'log', 'log10',
    'lower', 'max', 'memcpy', 'memorycopy', 'mergemethods', 'methods',
    'min', 'murmur3hash', 'newlist', 'nofprocessors', 'nothing',
    'nullpointer', 'nullptr', 'number', 'obj2ptr', 'object2pointer',
    'objectid', 'optionalfunc', 'packageclasses', 'packagename',
    'packages', 'parentclassname', 'perror', 'pointer2object',
    'pointer2string', 'pointercompare', 'pow', 'prevfilename', 'print',
    'print2str', 'ptr2obj', 'ptr2str', 'ptrcmp', 'puts', 'raise',
    'random', 'randomize', 'read', 'ref', 'reference', 'refcount',
    'remove', 'rename', 'reverse', 'rewind', 'right', 'ring_give',
    'ring_see', 'ring_state_delete', 'ring_state_filetokens',
    'ring_state_findvar', 'ring_state_init', 'ring_state_main',
    'ring_state_mainfile', 'ring_state_new', 'ring_state_newvar',
    'ring_state_resume', 'ring_state_runcode', 'ring_state_runcodeatins',
    'ring_state_runfile', 'ring_state_runobjectfile',
    'ring_state_scannererror', 'ring_state_setvar',
    'ring_state_stringtokens', 'ringvm_callfunc', 'ringvm_calllist',
    'ringvm_cfunctionslist', 'ringvm_classeslist', 'ringvm_codelist',
    'ringvm_evalinscope', 'ringvm_fileslist', 'ringvm_functionslist',
    'ringvm_genarray', 'ringvm_give', 'ringvm_hideerrormsg', 'ringvm_info',
    'ringvm_ismempool', 'ringvm_memorylist', 'ringvm_packageslist',
    'ringvm_passerror', 'ringvm_runcode', 'ringvm_scopescount',
    'ringvm_see', 'ringvm_settrace', 'ringvm_tracedata',
    'ringvm_traceevent', 'ringvm_tracefunc', 'setattribute', 'setpointer',
    'setptr', 'shutdown', 'sin', 'sinh', 'sort', 'space', 'sqrt',
    'srandom', 'str2hex', 'str2hexcstyle', 'str2list', 'strcmp', 'string',
    'substr', 'swap', 'sysget', 'sysset', 'syssleep', 'system', 'sysunset',
    'tan', 'tanh', 'tempfile', 'tempname', 'time', 'timelist', 'trim',
    'type', 'ungetc', 'unsigned', 'upper', 'uptime', 'variablepointer',
    'varptr', 'version', 'windowsnl', 'write'
  ];

  const IDENTIFIER = /[a-zA-Z_@$][\w@$]*/;

  return {
    name: 'Ring',
    case_insensitive: true,
    keywords: KEYWORDS,
    contains: [
      // Single-line comments
      hljs.COMMENT('//', '$'),
      hljs.COMMENT('#', '$'),
      
      // Multi-line comments
      hljs.COMMENT('/\\*', '\\*/', {
        contains: ['self']
      }),

      // Scanner commands (preprocessor-like)
      {
        className: 'meta',
        begin: '^\\s*(' + SCANNER_COMMANDS.join('|') + ')\\b',
        relevance: 10
      },

      // String literals with interpolation support
      {
        className: 'string',
        begin: '"',
        end: '"',
        contains: [
          hljs.BACKSLASH_ESCAPE,
          {
            className: 'subst',
            begin: '#\\{',
            end: '\\}',
            contains: ['self']
          }
        ]
      },
      {
        className: 'string',
        begin: "'",
        end: "'",
        contains: [
          hljs.BACKSLASH_ESCAPE,
          {
            className: 'subst',
            begin: '#\\{',
            end: '\\}',
            contains: ['self']
          }
        ]
      },
      {
        className: 'string',
        begin: '`',
        end: '`',
        contains: [
          hljs.BACKSLASH_ESCAPE,
          {
            className: 'subst',
            begin: '#\\{',
            end: '\\}',
            contains: ['self']
          }
        ]
      },

      // Symbol literals
      {
        className: 'symbol',
        begin: ':' + IDENTIFIER.source
      },

      // Class declarations - highlight only the class name
      {
        className: 'keyword',
        begin: '\\bclass\\b',
        end: /(?=\s)/,
        relevance: 0
      },
      {
        className: 'title.class',
        begin: '(?<=\\bclass\\s+)' + IDENTIFIER.source,
        relevance: 10
      },

      // Function declarations - highlight only the function name
      {
        className: 'keyword',
        begin: '\\b(func|def|function)\\b',
        end: /(?=\s)/,
        relevance: 0
      },
      {
        className: 'title.function',
        begin: '(?<=\\b(?:func|def|function)\\s+)' + IDENTIFIER.source,
        relevance: 10
      },

      // Package/import declarations - highlight only the package name
      {
        className: 'keyword',
        begin: '\\b(package|import)\\b',
        end: /(?=\s)/,
        relevance: 0
      },
      {
        className: 'title.class.inherited',
        begin: '(?<=\\b(?:package|import)\\s+)[a-zA-Z_@$][\\w@$.]*',
        relevance: 10
      },

      // From declarations (inheritance)
      {
        className: 'keyword',
        begin: '\\bfrom\\b',
        end: /(?=\s)/,
        relevance: 0
      },
      {
        className: 'title.class.inherited',
        begin: '(?<=\\bfrom\\s+)' + IDENTIFIER.source,
        relevance: 10
      },

      {
        className: 'keyword',
        begin: '\\bnew\\b',
        end: /(?=\s)/,
        relevance: 0
      },
      {
        className: 'title.class',
        begin: '(?<=\\bnew\\s+)' + IDENTIFIER.source,
        relevance: 10
      },

      // Built-in functions
      {
        className: 'built_in',
        begin: '\\b(' + BUILTIN_FUNCTIONS.join('|') + ')(?=\\s*\\()'
      },

      // Regular function calls
      {
        className: 'title.function.invoke',
        begin: '\\b' + IDENTIFIER.source + '(?=\\s*\\()',
        relevance: 0
      },

      // Numbers
      {
        className: 'number',
        variants: [
          { begin: '\\b0x[a-f0-9_]+\\b' },
          { begin: '\\b0b[01_]+\\b' },
          { begin: '\\b0o[0-7_]+\\b' },
          { begin: '\\b[0-9]+(?:_[0-9]+)*\\.[0-9]*(?:_[0-9]+)*([eE][-+]?[0-9]+)?\\b' },
          { begin: '\\b[0-9]+(?:_[0-9]+)*\\b' }
        ]
      },

      // Operators
      {
        className: 'operator',
        begin: /(\+\+|\-\-|\*\*|\^\^|!=|<=|>=|<<|>>|&&|\|\||\+=|-=|\*=|\/=|%=|<<=|>>=|&=|\|=|\^=|[-+\/*%=<>&|!~.:^?])/
      }
    ]
  };
}

module.exports = ring;
//
//  PgEntry.cpp
//  PgImageAlgoResManager
//
//  Created by Camera360 on 2018/10/30.
//  Copyright © 2018 vstudio. All rights reserved.
//

#include "PgEntry.hpp"
#include "bx/file.h"

namespace entry {
    static bx::FileReaderI* s_fileReader = NULL;
    static bx::FileWriterI* s_fileWriter = NULL;
    
    extern bx::AllocatorI* getDefaultAllocator();
    bx::AllocatorI* g_allocator = getDefaultAllocator();
    
    
#if ENTRY_CONFIG_IMPLEMENT_DEFAULT_ALLOCATOR
    bx::AllocatorI* getDefaultAllocator()
    {
        BX_PRAGMA_DIAGNOSTIC_PUSH();
        BX_PRAGMA_DIAGNOSTIC_IGNORED_MSVC(4459); // warning C4459: declaration of 's_allocator' hides global declaration
        BX_PRAGMA_DIAGNOSTIC_IGNORED_CLANG_GCC("-Wshadow");
        static bx::DefaultAllocator s_allocator;
        return &s_allocator;
        BX_PRAGMA_DIAGNOSTIC_POP();
    }
#endif // ENTRY_CONFIG_IMPLEMENT_DEFAULT_ALLOCATOR
    
    bx::FileReaderI* getFileReader()
    {
        init();
        return s_fileReader;
    }
    
    bx::FileWriterI* getFileWriter()
    {
        init();
        return s_fileWriter;
    }
    
    bx::AllocatorI* getAllocator()
    {
        if (NULL == g_allocator)
        {
            g_allocator = getDefaultAllocator();
        }
        
        return g_allocator;
    }
    
    void init()
    {
        if (s_fileReader == NULL)
        {
            s_fileReader = BX_NEW(g_allocator, bx::FileReader);
        }
        if (s_fileWriter == NULL)
        {
            s_fileWriter = BX_NEW(g_allocator, bx::FileWriter);
        }
    }
    
    void unInit()
    {
        if (s_fileReader != NULL)
        {
            BX_DELETE(g_allocator, s_fileReader);
            s_fileReader = NULL;
        }

        if (s_fileWriter != NULL)
        {
            BX_DELETE(g_allocator, s_fileWriter);
            s_fileWriter = NULL;
        }
    }
}

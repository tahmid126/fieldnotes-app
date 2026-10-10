package com.fieldnotes.security;

import com.fieldnotes.common.exception.BadRequestException;
import com.fieldnotes.user.User;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

public final class SecurityUtils {

    private SecurityUtils() {}

    public static User getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof User)) {
            throw new BadRequestException("No authenticated user found in security context");
        }
        return (User) authentication.getPrincipal();
    }
}

package com.smartlivestock.service;

import com.smartlivestock.dto.UserDto;

import java.util.List;

/**
 * 用户服务接口
 */
public interface UserService {
    
    UserDto createUser(UserDto userDto);
    
    UserDto getUserById(Long id);
    
    UserDto getUserByUsername(String username);
    
    List<UserDto> getAllUsers();
    
    UserDto updateUser(Long id, UserDto userDto);
    
    void deleteUser(Long id);
    
    boolean existsByUsername(String username);
    
    boolean existsByEmail(String email);
    
    UserDto updateUserRole(Long id, String role);
    
    UserDto updateUserStatus(Long id, boolean isActive);
    
    UserDto updateLastLogin(Long id);
} 
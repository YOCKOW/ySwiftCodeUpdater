/* *************************************************************************************************
 CodeUpdaterError.swift
   © 2019,2024 YOCKOW.
     Licensed under MIT License.
     See "LICENSE.txt" for more information.
 ************************************************************************************************ */

public enum CodeUpdaterError: Error, Sendable {
  case cannotConvertToString
  case cannotConvertToData
}
